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

const VARS = ['M1', 'M2', 'M3'];
const STATES = ['published', 'retired', 'draft'];

/* ---------- EL RESET ES OBLIGATORIO Y LO DESCUBRIÓ UN CHECK EN ROJO ----------
   Abrir el menú o la hoja les da foco al primer ítem, y enfocar algo dentro del `.scroller` LO SCROLLEA.
   Sin esto, el check 7 leía la geometría de la cabecera con la página ya corrida (name: -240) y el
   recorte del check 8 salía con `y` negativo — un número verdadero sobre una página que no era la que
   la variante muestra al reposo. Es la misma familia que la trampa del `opacity: 0` de la 074: medir
   bien algo que no está donde se cree. Cada set deja la página en reposo. */
const atRest = p => p.evaluate(() => {
  const m = document.querySelector('#menu'); m.hidden = true; m.innerHTML = '';
  document.querySelector('#mscrim').hidden = true;
  document.querySelector('#sheet').classList.remove('open');
  document.querySelector('#backdrop').classList.remove('open');
  document.querySelector('#dscrim').classList.remove('open');
  const sc = document.querySelector('#scroller'); sc.scrollTop = 0;
  document.querySelector('#tbar').classList.remove('titled');
  /* EL SNACK TAMBIÉN. Sin esto, la captura de M2 salió con un `Juego despublicado` de un check anterior
     sentado justo encima de la zona CICLO — y por accidente mostró el choque que ahora mide el check 17.
     El accidente vale como hallazgo; dejarlo dentro del arnés no, porque contamina todo lo demás. */
  document.querySelector('#snack').classList.remove('show');
});
const setVar = async (p, v) => { await p.evaluate(v => { document.querySelector(`#vnav [data-var="${v}"]`).click(); }, v); await atRest(p); };
const setState = async (p, s) => { await p.evaluate(s => { document.querySelector(`#tools [data-cy="${s}"]`).click(); }, s); await atRest(p); };
const hideTools = p => p.evaluate(() => { document.querySelector('#tools').hidden = true; document.querySelector('#vnav').style.visibility = 'hidden'; });
const showTools = p => p.evaluate(() => { document.querySelector('#tools').hidden = false; document.querySelector('#vnav').style.visibility = ''; });

/* si el arnés revienta a mitad de camino, lo que YA se midió se imprime igual. Sin esto un error en el
   check 14 borra los trece anteriores de la pantalla y parece que no se midió nada. */
const dump = e => { console.log(log.join('\n')); console.error('\nREVENTÓ: ' + (e && e.message)); process.exit(2); };
process.on('uncaughtException', dump);
process.on('unhandledRejection', dump);

(async () => {
  /* 078:108 verbatim — playwright-core viene sin navegador acá, así que se usa el Chrome del sistema. */
  const exe = [process.env.CHROME_BIN, '/usr/bin/google-chrome-stable', '/usr/bin/google-chrome', '/usr/bin/chromium-browser']
    .filter(Boolean).find(p => fs.existsSync(p));
  const browser = await chromium.launch(exe ? { executablePath: exe } : {});
  const page = await browser.newPage({ viewport: { width: 900, height: 900 }, deviceScaleFactor: 2 });
  const errs = [];
  page.on('pageerror', e => errs.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
  await page.goto(URL, { waitUntil: 'networkidle' });

  /* ---------- 0 · el panel no se come los hit tests ---------- */
  await hideTools(page);
  ok(await page.evaluate(() => {
    const t = document.querySelector('#tools');
    return t.offsetParent === null;
  }), '0 · el panel de herramientas está realmente fuera de layout durante los hit tests (offsetParent, no .hidden)');
  await showTools(page);

  /* ============================================================================
     1 · NO ATRIBUIBLE — las tres variantes leen el MISMO array
     Es la disciplina de `missing()` en la 078 (check 4). Si M1 ofreciera dos ítems
     y M2 tres, todo hallazgo sobre el contenedor sería en realidad sobre el
     contenido.
     ============================================================================ */
  const byVar = {};
  for (const v of VARS) {
    await setVar(page, v);
    byVar[v] = await page.evaluate(ss => ss.map(s => window.actions(s).map(a => a.id).join(',')), STATES);
  }
  ok(JSON.stringify(byVar.M1) === JSON.stringify(byVar.M2) && JSON.stringify(byVar.M2) === JSON.stringify(byVar.M3),
    `1 · las tres variantes computan las MISMAS transiciones en los tres estados — ${JSON.stringify(byVar.M1)}`);

  /* 1b · el negativo: si `actions` se puede pisar desde el arnés, el check 1 puede fallar.
     Sin esto, el 1 pasaría igual si las tres variantes leyeran una constante muerta. */
  const falsifiable = await page.evaluate(() => {
    const real = window.actions;
    window.actions = s => (s === 'published' ? [{ id: 'X' }] : real(s));
    const tampered = window.actions('published').map(a => a.id).join(',');
    window.actions = real;
    return tampered === 'X' && real('published').map(a => a.id).join(',') === 'unpublish,retire';
  });
  ok(falsifiable, '1b · NEGATIVO — `actions` es alcanzable y pisable desde el arnés, así que el check 1 puede fallar de verdad');

  /* ============================================================================
     2 · EL NÚMERO QUE DECIDE SI UN MENÚ ES UN MENÚ
     Medido ANTES de mirar ningún contenedor, que es la instrucción de la ronda.
     ============================================================================ */
  const counts = await page.evaluate(ss => ss.map(s => [s, window.actions(s).length]), STATES);
  const cmap = Object.fromEntries(counts);
  ok(cmap.published === 2, `2a · publicado ofrece ${cmap.published} transiciones (Despublicar + Retirar)`);
  ok(cmap.retired === 1, `2b · retirado ofrece ${cmap.retired} — `
    + `un menú de UN ítem es un botón con un toque de más y la etiqueta escondida`);
  ok(cmap.draft === 0, `2c · borrador ofrece ${cmap.draft} — no llega a esta página: la 078 manda la fila de borrador a la HOJA`);

  /* ============================================================================
     3 · QUÉ SE VE AL REPOSO, SIN TOCAR NADA
     El eje que la ronda nombró: el ⋮ es una salida a la prohibición de botones
     deshabilitados de la 064 — una opción se ESCONDE en vez de deshabilitarse —
     pero esconderla también esconde que existe. Esto lo cuenta.
     ============================================================================ */
  const rest = {};
  for (const v of VARS) {
    await setVar(page, v); await setState(page, 'published');
    rest[v] = await page.evaluate(() => {
      const laid = el => !!el && el.offsetParent !== null;
      /* los VERBOS visibles al reposo, contados por offsetParent — nunca por .hidden */
      const verbs = [...document.querySelectorAll('#main [data-cyc], #menu:not([hidden]) [data-cyc]')].filter(laid);
      return {
        verbs: verbs.map(b => b.textContent.trim().split('\n')[0].trim()),
        kebab: laid(document.querySelector('#kebab')),
        ctl: laid(document.querySelector('#cycctl'))
      };
    });
  }
  ok(rest.M1.verbs.length === 0 && rest.M1.kebab,
    `3a · M1 al reposo muestra ${rest.M1.verbs.length} verbos y un ⋮ — el glifo dice que hay algo, no QUÉ`);
  ok(rest.M2.verbs.length === 2,
    `3b · M2 al reposo muestra los ${rest.M2.verbs.length} verbos en palabras — ${JSON.stringify(rest.M2.verbs)}`);
  ok(rest.M3.verbs.length === 0 && rest.M3.ctl,
    `3c · M3 al reposo muestra ${rest.M3.verbs.length} verbos; lo único que hay es la línea de estado hecha control`);

  /* 3d · EL CONTENEDOR VACÍO NO PRUEBA NADA. El mismo cero de M1 se ve si `actions()` devolvió cero.
     Abrir el menú sobre el mismo estado es lo que separa "escondido" de "inexistente". */
  await setVar(page, 'M1'); await setState(page, 'published');
  const opened = await page.evaluate(() => {
    document.querySelector('#kebab').click();
    const m = document.querySelector('#menu');
    return { laid: m.offsetParent !== null, items: [...m.querySelectorAll('.mi')].map(b => b.textContent.trim()) };
  });
  ok(opened.laid && opened.items.length === 2,
    `3d · POSITIVO del 3a — abierto, el menú de M1 sí tiene los dos: ${JSON.stringify(opened.items)}`);

  /* ---------- 4 · toques hasta la transición ---------- */
  const taps = { M1: 2, M2: 1, M3: 2 };
  await page.evaluate(() => document.querySelector('#mscrim').click());
  const realTaps = {};
  for (const v of VARS) {
    await setVar(page, v); await setState(page, 'published');
    realTaps[v] = await page.evaluate(v => {
      let n = 0;
      if (v === 'M1') { document.querySelector('#kebab').click(); n++; }
      if (v === 'M3') { document.querySelector('#cycctl').click(); n++; }
      const t = document.querySelector('[data-cyc="unpublish"]');
      if (!t) return -1;
      t.click(); n++;
      return n;
    }, v);
    /* cerrar el diálogo que quedó abierto */
    await page.evaluate(() => document.querySelector('[data-act="dlg-no"]')?.click());
  }
  ok(JSON.stringify(realTaps) === JSON.stringify(taps),
    `4 · toques hasta Despublicar — M1 ${realTaps.M1} · M2 ${realTaps.M2} · M3 ${realTaps.M3}`);

  /* ============================================================================
     5 · 064 — NINGÚN CONTROL DE CICLO DESHABILITADO, EN NINGUNA VARIANTE
     La 078 contó SIETE excepciones a la prohibición de la 064. Esta ronda no
     agrega la octava: donde una transición no aplica, no se dibuja.
     ============================================================================ */
  let disabled = 0; const strays = [];
  for (const v of VARS) for (const s of STATES) {
    await setVar(page, v); await setState(page, s);
    const r = await page.evaluate(() => ({
      dis: document.querySelectorAll('[data-cyc][disabled], #kebab[disabled], #cycctl[disabled]').length,
      /* cada nodo sobrante se REPORTA con su selector — un contador pelado dice que algo sobra y no qué,
         y el primer rojo de este check costó una vuelta entera averiguándolo */
      any: [...document.querySelectorAll('[data-cyc], #kebab, #cycctl')]
        .map(e => (e.id ? '#' + e.id : e.tagName.toLowerCase() + '[data-cyc=' + e.dataset.cyc + ']') + ' en ' + (e.closest('#menu,#sheet,#main,#tbar')?.id || '?')),
      n: window.actions(document.querySelector('#tools [data-cy].on').dataset.cy).length
    }));
    disabled += r.dis;
    if (r.n === 0 && r.any.length) strays.push(`${v}/${s}: ${r.any.join(', ')}`);
  }
  ok(disabled === 0, `5a · cero controles de ciclo deshabilitados en 3 variantes × 3 estados (064 sin una octava excepción)`);
  ok(strays.length === 0, `5b · y donde no hay transición no queda contenedor NI NODO — ni ⋮, ni zona, ni control`
    + (strays.length ? ` — sobran: ${strays.join(' | ')}` : ''));

  /* ============================================================================
     6 · EL COSTO DE M1, MEDIDO EN LA REGLA QUE ROMPE
     d42: *"el primario siempre termina en el mismo borde"* — R359 en la 074, y
     074 ronda 3 volvió a poner la tinta de W3 exactamente ahí. Meter un ⋮ a su
     derecha lo EMPUJA. No es una opinión sobre el glifo: es la regla que el
     linaje entero sostuvo durante tres sketches.
     ============================================================================ */
  const edge = {};
  for (const v of VARS) {
    await setVar(page, v); await setState(page, 'published');
    edge[v] = await page.evaluate(() => {
      const d = document.querySelector('#device').getBoundingClientRect();
      const b = document.querySelector('#save').getBoundingClientRect();
      const k = document.querySelector('#kebab')?.getBoundingClientRect();
      return { save: Math.round(b.right - d.left), kebab: k ? Math.round(k.right - d.left) : null };
    });
  }
  ok(edge.M2.save === edge.M3.save && edge.M2.save === 359,
    `6a · M2 y M3 dejan el borde de Guardar en R${edge.M2.save} — la quilla de 16px de d42, intacta`);
  ok(edge.M1.save < edge.M2.save,
    `6b · M1 lo empuja a R${edge.M1.save} — ${edge.M2.save - edge.M1.save}px adentro, y quien queda en la quilla es el ⋮ (R${edge.M1.kebab})`);

  /* 6c · el negativo del 6b: si el ⋮ no estuviera, el borde volvería a R359. Sin esto, el 6b podría
     estar midiendo cualquier otra cosa que mueva la barra. */
  await setVar(page, 'M1'); await setState(page, 'published');
  const without = await page.evaluate(() => {
    const k = document.querySelector('#kebab');
    if (!k) return null;                      /* si no hay ⋮ el negativo no prueba nada — se reporta null y falla */
    k.remove();
    const d = document.querySelector('#device').getBoundingClientRect();
    return Math.round(document.querySelector('#save').getBoundingClientRect().right - d.left);
  });
  ok(without === 359, `6c · NEGATIVO — sacando el ⋮ de M1, Guardar vuelve solo a R${without}: el empuje es del glifo y de nada más`);

  /* ============================================================================
     7 · M3 NO MUEVE TEXTO
     075-V4 perdió una ronda a `font: inherit`, que resetea el `line-height` y le
     bajó el spine 8px — un pixel-diff habría reportado mi CSS como affordance.
     La geometría se asserta ANTES de leer ningún diff.
     ============================================================================ */
  const geo = {};
  for (const v of ['M2', 'M3']) {
    await setVar(page, v); await setState(page, 'published');
    geo[v] = await page.evaluate(() => {
      const d = document.querySelector('#device').getBoundingClientRect();
      const nm = document.querySelector('.gh-name').getBoundingClientRect();
      const dot = document.querySelector('.gh-st .dot').getBoundingClientRect();
      const lbl = document.querySelector('.glabel').getBoundingClientRect();
      return { name: Math.round(nm.top - d.top), dotX: Math.round(dot.left - d.left), dotY: Math.round(dot.top - d.top), label: Math.round(lbl.top - d.top) };
    });
  }
  ok(JSON.stringify(geo.M2) === JSON.stringify(geo.M3),
    `7 · M3 no mueve ni el nombre, ni el punto, ni el label de abajo — M2 ${JSON.stringify(geo.M2)} · M3 ${JSON.stringify(geo.M3)}`);

  /* ============================================================================
     8 · EL PIXEL-DIFF QUE 075-V4 DEJÓ VIVO
     Dibujado puro, "el diagnóstico ES el remedio" dio `diffPx 0`: indistinguible
     de la variante donde no hacía nada. Acá el riesgo es peor, porque la línea
     de estado es más chica que un bloque de prosa. El 8b mantiene vivo el
     resultado puro: sacándole la banda, el diff TIENE que volver a cero.
     ============================================================================ */
  await hideTools(page);
  const clip = await page.evaluate(() => {
    const r = document.querySelector('.gh-st').getBoundingClientRect();
    return { x: Math.floor(r.left) - 14, y: Math.floor(r.top) - 4, width: 210, height: Math.ceil(r.height) + 8 };
  });
  await setVar(page, 'M2'); await setState(page, 'published');
  const shotM2 = await page.screenshot({ clip });
  await setVar(page, 'M3'); await setState(page, 'published');
  const shotM3 = await page.screenshot({ clip });
  fs.writeFileSync(path.join(OUT, 'M2-head.png'), shotM2);
  fs.writeFileSync(path.join(OUT, 'M3-head.png'), shotM3);
  const dA = diffPNG(shotM2, shotM3);
  ok(dA.diffPx > 0, `8a · con la banda de d29, M3 se distingue del read-out inerte de M2 — `
    + `diffPx ${dA.diffPx} de ${dA.total} · maxDelta ${dA.maxDelta}${dA.note && ' · ' + dA.note}`);

  /* 8c · antes de creerle a ningún diff: ¿el recorte contiene la banda? Un recorte que la dejara afuera
     haría que 8a fuera imposible de pasar y 8b imposible de fallar — la trampa nueva de esta ronda. */
  const inClip = await page.evaluate(c => {
    const el = document.querySelector('#cycctl');
    const r = el.getBoundingClientRect();
    const band = { x: r.left, y: r.top, w: 3, h: r.height };
    return band.x >= c.x && band.x + band.w <= c.x + c.width && band.y >= c.y && band.y + band.h <= c.y + c.height;
  }, clip);
  ok(inClip, '8c · el recorte contiene la banda entera, así que 8a y 8b hablan de ella y no del recorte');

  const shotM3bare = await page.evaluate(() => {
    const s = document.createElement('style');
    s.id = 'nb'; s.textContent = '.gh-st.ctl::before { content: none !important; }';
    document.head.appendChild(s);
  }).then(() => page.screenshot({ clip }));
  fs.writeFileSync(path.join(OUT, 'M3-head-sin-banda.png'), shotM3bare);
  /* ---------- 8b · EL DIFF CONTRA M2 NO PUEDE AISLAR LA BANDA, Y ESO ES EL HALLAZGO ----------
     La primera versión afirmaba que M3 sin banda tenía que volver a ser idéntico a M2, copiando el
     `diffPx 0 of 270000` de 075-V4. Dio 2535 de 31920 con maxDelta 91.
     La causa NO es pintura: la geometría entera coincide (check 7, redondeada al píxel) y ningún color
     computado difiere. Es que un `<button>` con ancho de ajuste al contenido mide 231,141px contra los
     265 del `<div>`, y ese ancho fraccionario corre las posiciones subpíxel de las letras, así que el
     mismo texto se rasteriza distinto. Invisible a ojo — maxDelta 91 sobre glifos antialiaseados — pero
     imposible de separar de un affordance real por un diff.
     O sea: LA COMPARACIÓN DE 075-V4 NO ES PORTABLE ACÁ. Allá las dos variantes eran el mismo `<div>` y
     el único cambio era pintura. Acá el contenedor cambia de tipo de caja. El diff se reporta como
     número, y la banda se aísla contra M3-SIN-BANDA en el 8d, que es la única comparación en la que las
     dos imágenes tienen la misma caja. */
  const dB = diffPNG(shotM2, shotM3bare);
  ok(dB.diffPx > 0 && dB.maxDelta < 128,
    `8b · TRAMPA MEDIDA — M3 sin banda todavía difiere de M2 en ${dB.diffPx} px de ${dB.total} (maxDelta ${dB.maxDelta}), `
    + `y no por pintura: el <button> mide 231,141px contra 265 del <div>, y el ancho fraccionario corre el subpíxel de las letras. `
    + `El diff contra M2 NO aísla la banda; el 8d sí.`);

  const dC = diffPNG(shotM3bare, shotM3);
  ok(dC.diffPx > 0,
    `8d · la banda de d29, aislada contra la MISMA caja: diffPx ${dC.diffPx} de ${dC.total} · maxDelta ${dC.maxDelta}. `
    + `Es lo único que separa "la línea de estado es un control" de "la línea de estado no hace nada" — `
    + `y en 075-V4 esa diferencia, sin banda, fue exactamente cero.`);
  await page.evaluate(() => document.querySelector('#nb')?.remove());
  await showTools(page);

  /* ============================================================================
     9 · EL DESTINO DE DESPUBLICAR, EVALUADO CONTRA EL CÓDIGO DE LA 078
     No lo afirmo: corro los predicados REALES de la 078 contra la fila que queda
     después de despublicar. Si la 078 cambia, este check se entera.
     ============================================================================ */
  const s078 = fs.readFileSync(path.join(ROOT, '.planning/sketches/078-admin-publish-gate/index.html'), 'utf8');
  const groupsSrc = (s078.match(/const GROUPS = \[[\s\S]*?\n\];/) || [])[0];
  const opensSrc = (s078.match(/function opensSheet\(g\)[^\n]*\n?/) || [])[0];
  /* `opensSheet` llama a `enrOf`, que vive en otra línea del mismo archivo. Traerlo también, en vez de
     escribirlo a mano acá, es lo que mantiene al check atado al archivo: si la 078 cambia cualquiera de
     los dos, esto se entera. Escribir `enrOf` de memoria sería exactamente la clase de transcripción que
     el 9a existe para prohibir. */
  const enrSrc = (s078.match(/const enrOf = [^\n]*\n?/) || [])[0];
  ok(!!groupsSrc && !!opensSrc && !!enrSrc, '9a · los tres predicados de la 078 se leyeron del archivo, no se transcribieron acá');
  const landing = await page.evaluate(([gs, os2, es]) => {
    const enrOf = eval('(' + es.replace('const enrOf =', '').replace(/;\s*$/, '') + ')');
    const GROUPS = eval(gs.replace('const GROUPS =', '(').replace(/;\s*$/, ')'));
    const opensSheet = eval('(' + os2.replace('function opensSheet', 'function').replace(/;?\s*$/, '') + ')');
    const row = { status: 'draft', gap: false, enr: 'enriched' };
    const g = GROUPS.find(x => x.has(row));
    return { section: g.name, shut: !!g.shut, sheet: opensSheet(row) };
  }, [groupsSrc, opensSrc, enrSrc]);
  ok(landing.section === 'Borradores' && landing.shut === true && landing.sheet === true,
    `9b · un publicado que despublicás cae en "${landing.section}" (sección cerrada al reposo: ${landing.shut}), pierde el chevron, `
    + `y al tocarla abre la hoja que te pide completar y PUBLICAR — o sea, deshacer lo que acabás de hacer`);

  /* 9c · y el destino no existe en el código: `:draft` es de una sola vía. */
  const gameEx = fs.readFileSync(path.join(ROOT, 'lib/pukllay_club/catalog/game.ex'), 'utf8');
  const catalogEx = fs.readFileSync(path.join(ROOT, 'lib/pukllay_club/catalog.ex'), 'utf8');
  /* contar `draft_changeset` a secas daba 2 en catalog.ex: uno es una MENCIÓN en un docstring (línea 299).
     Un check que cuenta menciones no está contando llamadas. Se cuentan sitios de llamada —
     `Game.draft_changeset(` — y por separado que el único esté dentro de un `Multi.insert`. */
  const draftWriters = (gameEx.match(/put_change\(:status,\s*:draft\)/g) || []).length;
  const callSites = catalogEx.split('\n').filter(l => /Game\.draft_changeset\(/.test(l));
  const insertOnly = callSites.every(l => /Multi\.insert\(/.test(l));
  ok(draftWriters === 1 && callSites.length === 1 && insertOnly,
    `9c · en todo game.ex hay ${draftWriters} escritura de \`:draft\` y en catalog.ex ${callSites.length} sitio de llamada, `
    + `y es un \`Multi.insert\` (${insertOnly}) — se entra a borrador al CREAR y nunca más. `
    + `"Despublicar" no es un botón que falta: es un destino que hoy no existe.`);

  /* ============================================================================
     10 · "RETIRAR" DICE LO QUE NO ES — y lo dice el archivo, no yo
     Se compara la copia del diálogo dibujada acá contra form.ex carácter por
     carácter. Si alguien arregla la copia en el código, este check se rompe, que
     es lo que uno quiere que pase.
     ============================================================================ */
  const formEx = fs.readFileSync(path.join(ROOT, 'lib/pukllay_club_web/live/admin/game_live/form.ex'), 'utf8');
  const shipped = 'Vas a poder restaurarlo después. No va a aparecer más en la ludoteca pública.';
  ok(formEx.includes(shipped),
    `10a · la copia del diálogo de Retirar que corre hoy (form.ex) es, literal: "${shipped}"`);
  await setVar(page, 'M2'); await setState(page, 'published');
  const drawn = await page.evaluate(() => {
    document.querySelector('[data-cyc="retire"]').click();
    const t = document.querySelector('#dlg-d').textContent;
    document.querySelector('[data-act="dlg-no"]').click();
    return t;
  });
  ok(drawn === shipped, '10b · la página dibuja esa copia sin retocarla, para que el hallazgo sea del código y no de mi redacción');
  /* el hallazgo en sí: esa frase describe DESPUBLICAR. "el club ya no tiene el juego" no aparece. */
  ok(/no va a aparecer más en la ludoteca pública/i.test(shipped) && !/ya no (lo )?tien|se vendió|se perdió|no está más en el club/i.test(shipped),
    '10c · esa copia describe DESPUBLICAR (deja de verse en la web, reversible) y no dice en ningún lado que el club ya no tenga el juego');

  /* 10d · y el otro sentido de `retired` SÍ está en el código, en otro archivo: shelves.ex lo trata como
     "no está en la colección física". Dos significados, dos archivos, en desacuerdo. */
  const shelvesEx = fs.readFileSync(path.join(ROOT, 'lib/pukllay_club/catalog/shelves.ex'), 'utf8');
  const shelfFilters = (shelvesEx.match(/status\s*!=\s*:retired/g) || []).length;
  ok(shelfFilters >= 4,
    `10d · shelves.ex excluye \`:retired\` en ${shelfFilters} consultas (ubicación, sin ubicar, en estante, pick list): ahí `
    + `\`retired\` significa "el club no lo tiene". El diálogo dice "no se ve en la web". Un estado, dos significados.`);

  /* ============================================================================
     11 · EL PLIEGUE — donde murió la V3 de la 075
     La 078 sacó la barra de tabs (destino a pantalla completa), así que el piso
     es 740, no 673. Ese detalle es justamente el que la 075 midió mal en favor
     de V3, así que acá se mide contra el device Y con hit test.
     ============================================================================ */
  await setVar(page, 'M2'); await setState(page, 'published');
  await hideTools(page);
  const fold = await page.evaluate(() => {
    const d = document.querySelector('#device').getBoundingClientRect();
    const z = document.querySelector('#cyczone').getBoundingClientRect();
    /* fila POR FILA, y cada una con hit test: "la zona es visible" es una media verdad si la segunda
       acción está cortada. La 075 midió V3 contra el rect del scroller (740) en vez de contra lo que el
       ojo ve (673, por la barra de tabs encima) y el error salió A FAVOR de la variante. Acá la 078 sacó
       la barra, así que el piso ES el device — pero eso hay que afirmarlo midiendo, no heredarlo. */
    const rows = [...document.querySelectorAll('#cyczone .cact')].map(el => {
      const r = el.getBoundingClientRect();
      const hit = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
      return {
        label: el.textContent.trim().split('\n')[0].slice(0, 12),
        top: Math.round(r.top - d.top), bottom: Math.round(r.bottom - d.top),
        entera: r.bottom <= d.bottom,
        tocable: !!(hit && hit.closest('#cyczone .cact'))
      };
    });
    return { top: Math.round(z.top - d.top), floor: Math.round(d.height), rows };
  });
  await showTools(page);
  ok(fold.floor === 740, `11a · el piso es ${fold.floor}px — la 078 sacó la barra de tabs, así que nada superpone al scroller`);

  /* ---------- 11b · LO QUE LA MEDICIÓN DESMINTIÓ ----------
     Este check estaba escrito para asertar `visible === false`: la predicción era que M2 moriría en el
     pliegue como la V3 de la 075. LA MEDICIÓN DIJO LO CONTRARIO y el check se reescribió para medir en
     vez de para confirmar. Se deja anotado porque una aserción escrita antes de medir que después se
     ajusta al resultado es la forma exacta en que un arnés deja de poder fallar. */
  const enteras = fold.rows.filter(r => r.entera && r.tocable).length;
  ok(fold.rows.length === 2 && enteras >= 1,
    `11b · la zona CICLO de M2 arranca en y=${fold.top}, SOBRE el piso de ${fold.floor} — `
    + fold.rows.map(r => `${r.label} y${r.top}-${r.bottom} ${r.entera && r.tocable ? 'entera y tocable' : 'CORTADA'}`).join(' · ')
    + `. NO es el caso de V3 (que quedaba entera detrás de la barra de tabs): acá la 078 sacó la barra y el editor mide poco.`);
  /* ---------- 11c QUEDA EN ROJO A PROPÓSITO ----------
     No es una aserción rota: es el costo de M2, contado. La primera acción entra entera; la segunda
     cruza el piso. Así que M2 no muere en el pliegue como murió V3, pero tampoco ofrece las dos —
     ofrece UNA y media. Y cuál queda cortada depende del ORDEN, que no es un dato del diseño: hoy
     `Retirar` queda afuera porque `actions()` lo devuelve segundo. Rojo hasta que se decida. */
  ok(enteras === fold.rows.length,
    `11c · EL COSTO DE M2, EN ROJO A PROPÓSITO — al reposo entran ${enteras} de ${fold.rows.length} filas enteras. `
    + `"${fold.rows.find(r => !(r.entera && r.tocable))?.label}" cruza el piso de ${fold.floor}. `
    + `Cuál se corta lo decide el orden del array, no el diseño.`);

  /* 11c · pero acá el paseo es distinto de V3, y hay que decirlo: en el editor uno BAJA igual para leer
     la descripción. Se mide cuánto scroll hace falta contra cuánto tiene la página. */
  const scrollCost = await page.evaluate(() => {
    const sc = document.querySelector('#scroller');
    sc.scrollTop = sc.scrollHeight;
    const d = document.querySelector('#device').getBoundingClientRect();
    const z = document.querySelector('#cyczone').getBoundingClientRect();
    const r = { max: sc.scrollTop, topAfter: Math.round(z.top - d.top), visible: z.top < d.bottom };
    sc.scrollTop = 0;
    return r;
  });
  ok(scrollCost.visible === true,
    `11d · al fondo de la página sí aparece (y=${scrollCost.topAfter}), y el scroll total del editor es de ${scrollCost.max}px — `
    + `M2 no pide un scroll DE MÁS, pide el que la página ya tiene`);

  /* ---------- 12 · escape, scrim y foco ---------- */
  await setVar(page, 'M1'); await setState(page, 'published');
  const esc1 = await page.evaluate(async () => {
    document.querySelector('#kebab').click();
    const wasOpen = !document.querySelector('#menu').hidden;
    document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape', bubbles: true }));
    return { wasOpen, closed: document.querySelector('#menu').hidden };
  });
  ok(esc1.wasOpen && esc1.closed, '12a · Escape cierra el menú de M1 (y el positivo de que estaba abierto)');
  const scrimC = await page.evaluate(() => {
    document.querySelector('#kebab').click();
    document.querySelector('#mscrim').click();
    return document.querySelector('#menu').hidden;
  });
  ok(scrimC, '12b · un toque afuera también lo cierra');

  /* ---------- 13 · el menú no se corta contra el borde del device ----------
     `.device` tiene `overflow: hidden`: un menú que se pasara se recortaría EN SILENCIO. */
  await setVar(page, 'M1'); await setState(page, 'published');
  const clipped = await page.evaluate(() => {
    document.querySelector('#kebab').click();
    const d = document.querySelector('#device').getBoundingClientRect();
    const m = document.querySelector('#menu').getBoundingClientRect();
    const out = m.left < d.left || m.right > d.right || m.bottom > d.bottom;
    document.querySelector('#mscrim').click();
    return { out, w: Math.round(m.width), right: Math.round(d.right - m.right) };
  });
  ok(!clipped.out, `13 · el menú (${clipped.w}px) entra entero en el device, a ${clipped.right}px del borde derecho`);

  /* ---------- 14 · la transición realmente cambia el estado ----------
     Un contenedor que no commitea es pintura. La 078 encontró que G1 publicaba un borrador sin nivel
     con el botón visiblemente muerto — la forma opuesta del mismo defecto. */
  await setVar(page, 'M2'); await setState(page, 'published');
  const commit = await page.evaluate(() => {
    document.querySelector('[data-cyc="unpublish"]').click();
    document.querySelector('[data-act="dlg-yes"]').click();
    const after = document.querySelector('#tools [data-cy].on').dataset.cy;
    const dot = document.querySelector('.gh-st .dot').className;
    const txt = document.querySelector('.gh-st').textContent;
    return { after, dot, txt: txt.trim().split('·')[0].trim() };
  });
  ok(commit.after === 'draft' && /warn/.test(commit.dot) && commit.txt === 'Borrador',
    `14 · Despublicar commitea de verdad: el estado queda \`${commit.after}\` y el read-out pasa a "${commit.txt}" con su punto`);

  /* ============================================================================
     16-18 · LOS TRES QUE ENCONTRÓ LA PANTALLA, NO EL ARNÉS
     Novena, décima y undécima vez en este linaje. Ninguno de los tres era
     detectable por los checks que ya estaban: el 1 al 15 estaban todos verdes.
     ============================================================================ */

  /* ---------- 16 · el menú de M1 tapa el juego del que habla ----------
     En el momento exacto en que elegís entre "Despublicar" y "Retirar", la página deja de decirte
     QUÉ juego y EN QUÉ estado está. Misma forma que el choque toast/barra que la 078 midió en su
     check 16, pero peor en un sentido: lo tapado no es un anuncio, es la identidad del objeto. */
  await setVar(page, 'M1'); await setState(page, 'published');
  await hideTools(page);
  const occl = await page.evaluate(() => {
    document.querySelector('#kebab').click();
    const probe = sel => {
      const r = document.querySelector(sel).getBoundingClientRect();
      const hit = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
      return { tapado: !!(hit && hit.closest('#menu')), sobre: hit ? (hit.closest('#menu') ? '#menu' : (hit.className || hit.tagName)) : null };
    };
    const n = probe('.gh-name'), s = probe('.gh-st');
    const m = document.querySelector('#menu').getBoundingClientRect();
    const g = document.querySelector('.ghead').getBoundingClientRect();
    const ix = Math.max(0, Math.min(m.right, g.right) - Math.max(m.left, g.left));
    const iy = Math.max(0, Math.min(m.bottom, g.bottom) - Math.max(m.top, g.top));
    document.querySelector('#mscrim').click();
    return { name: n, st: s, overlap: Math.round(ix * iy) };
  });
  await showTools(page);
  ok(occl.name.tapado && occl.st.tapado,
    `16 · el menú abierto de M1 tapa el nombre del juego Y su estado (${occl.overlap}px² de la cabecera) — `
    + `elegís entre despublicar y retirar sin ver de qué juego ni desde qué estado`);

  /* ---------- 17 · d55 entierra la zona CICLO de M2 ----------
     La 078 midió que el toast de 10s tapaba su `Publicar`. Acá el snack de 4s aterriza exactamente
     sobre la zona de ciclo — y el snack que lo hace es EL DE LA PROPIA TRANSICIÓN. */
  await setVar(page, 'M2'); await setState(page, 'published');
  await hideTools(page);
  const snackHit = await page.evaluate(() => {
    document.querySelector('#snack').classList.add('show');
    const s = document.querySelector('#snack').getBoundingClientRect();
    const rows = [...document.querySelectorAll('#cyczone .cact')].map(el => {
      const r = el.getBoundingClientRect();
      const hit = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
      return { label: el.textContent.trim().split('\n')[0].slice(0, 11), sobre: hit ? (hit.closest('#snack') ? '#snack' : 'la fila') : 'nada' };
    });
    const lbl = document.querySelector('#cyczone .cyl').getBoundingClientRect();
    const cov = !(lbl.bottom < s.top || lbl.top > s.bottom);
    document.querySelector('#snack').classList.remove('show');
    return { rows, labelTapado: cov, zSnack: getComputedStyle(document.querySelector('#snack')).zIndex };
  });
  await showTools(page);
  const buried = snackHit.rows.filter(r => r.sobre === '#snack').length;
  ok(buried > 0 || snackHit.labelTapado,
    `17 · el snack (z-index ${snackHit.zSnack}) cae encima de la zona CICLO de M2 — label tapado: ${snackHit.labelTapado}, `
    + `filas enterradas: ${buried} de ${snackHit.rows.length} (${snackHit.rows.map(r => r.label + '→' + r.sobre).join(', ')}). `
    + `Y el snack que lo tapa es el de la transición que acabás de hacer ahí mismo. Misma forma que el check 16 de la 078.`);

  /* ---------- 18 · la banda de M3 cae en la canaleta, no sobre la línea ----------
     Encontrado mirando la captura: la banda de d29 aterriza EXACTAMENTE en el borde derecho de la tapa,
     dentro del gap de 14px de `.ghead`, así que se lee como un separador entre las dos columnas y no
     como un affordance de `● Publicado`. En 075-V4 la banda funcionaba porque el bloque era de ancho
     completo y no tenía nada a la izquierda. Acá tiene una tapa de 64px. */
  await setVar(page, 'M3'); await setState(page, 'published');
  const band = await page.evaluate(() => {
    const ctl = document.querySelector('#cycctl').getBoundingClientRect();
    const cov = document.querySelector('.ghead .cov').getBoundingClientRect();
    const dot = document.querySelector('#cycctl .dot').getBoundingClientRect();
    const name = document.querySelector('.gh-name').getBoundingClientRect();
    return {
      aLaTapa: Math.round(ctl.left - cov.right),      /* 0 = pegada al borde de la tapa */
      alPunto: Math.round(dot.left - ctl.left),        /* cuánto la separa del dato que marca */
      alNombre: Math.round(ctl.left - name.left),      /* negativo = está a la izquierda de la columna */
      alto: Math.round(ctl.height), altoLinea: Math.round(dot.height)
    };
  });
  ok(band.aLaTapa === 0 && band.alNombre < 0,
    `18 · la banda de M3 arranca a ${band.aLaTapa}px del borde de la tapa y ${Math.abs(band.alNombre)}px a la IZQUIERDA de la `
    + `columna de texto: cae en la canaleta de 14px de .ghead, no sobre la línea de estado. `
    + `Queda a ${band.alPunto}px del punto que supuestamente marca, y mide ${band.alto}px contra los ${band.altoLinea} del punto. `
    + `075-V4 no tenía este problema: allá el bloque era de ancho completo y no tenía una tapa a la izquierda.`);

  /* ---------- 19 · sin errores de consola ---------- */
  ok(errs.length === 0, `19 · consola limpia${errs.length ? ' — ' + errs.slice(0, 3).join(' | ') : ''}`);

  /* ---------- capturas ---------- */
  await hideTools(page);
  for (const v of VARS) {
    await setVar(page, v); await setState(page, 'published');
    await page.screenshot({ path: path.join(OUT, `${v}-reposo.png`), clip: await page.evaluate(() => {
      const r = document.querySelector('#device').getBoundingClientRect();
      return { x: r.x, y: r.y, width: r.width, height: r.height };
    }) });
  }
  await setVar(page, 'M1'); await page.evaluate(() => document.querySelector('#kebab').click());
  await page.screenshot({ path: path.join(OUT, 'M1-abierto.png'), clip: await page.evaluate(() => {
    const r = document.querySelector('#device').getBoundingClientRect();
    return { x: r.x, y: r.y, width: r.width, height: r.height };
  }) });
  await showTools(page);

  await browser.close();
  const pass = log.filter(l => l.startsWith('PASS')).length;
  console.log(log.join('\n'));
  console.log(`\n${pass}/${log.length}   capturas en ${OUT}`);
  process.exit(pass === log.length ? 0 : 1);
})();
