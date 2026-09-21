/* Headless-Chrome checks for sketch 078 — slice 3 of the create scenario: the draft, the publish gate,
   and the lifecycle. Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/078-admin-publish-gate/verify.js
   Env: PLAYWRIGHT_CORE, SKETCH_URL, SHOTS_DIR (default <os tmp>/sketch-078-shots).

   TODAS LAS PREGUNTAS ESTÁN CONTESTADAS Y LOS TOGGLES ELIMINADOS (convención de 072): el borrador se
   completa y se publica desde UNA HOJA abierta desde la lista, con UN solo botón, validación P2 (el botón
   nace muerto y revive al elegir el nivel, sin mensaje de error) y vuelta a la lista con la fila resaltada.
   La página del editor sobrevive SÓLO para un juego ya publicado.

   LO QUE LA PUERTA EXIGE ESTÁ MEDIDO, NO ELEGIDO, y sigue siendo el corazón de la hoja:
     · copias no es condición — se pre-carga en 1        (434/434 publicados tienen exactamente 1)
     · estante no es condición                            (1 de 435 lo tiene)
     · el nivel SÍ, salvo expansión                       (408/408 base · 0/26 expansiones)
     · y el nivel ES la sección                           (sections.rule_value, 1:1 contra la banda)

   Traps this file is written around — the first is new to this round, the rest inherited from 075-077,
   where each one produced a green number that described something other than the page.

     · UN BOTÓN DESHABILITADO NO PRUEBA UNA PUERTA: `#dpub[disabled]` es también lo que se ve si la hoja
       nunca se abrió. Todo check del estado muerto va acompañado del estado VIVO sobre la misma hoja.
     · CLICKING A WALK BUTTON THROUGH PLAYWRIGHT'S `click()` FAILS WHILE `#tools` IS HIDDEN. Every step is
       dispatched with `el.click()` inside `evaluate`; the panel is hidden only around screenshots.
     · A top-level `const`/`let` in a classic script is a LEXICAL BINDING, not a property of `window`, so a
       harness assignment changes nothing while appearing to (076, twice; 077 once). `missing` is a function
       DECLARATION reached through `window`, so check 12 can actually falsify checks 3 and 6.
     · The tool panel is `position: fixed` OVER the device and swallows `elementFromPoint`. Check 0 asserts
       it is really hidden before any hit test.
     · `#snack` carrying `.show` does not tell you WHICH snack it is (077). Every snack assertion reads
       `#snack span` text. */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();
const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/078-admin-publish-gate/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-078-shots'); fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);

const GATES = ['G1', 'G2', 'G3'];
const step = (p, k) => p.evaluate(k => document.querySelector(`[data-walk="${k}"]`).click(), k);
const setGate = (p, v) => p.evaluate(v => document.querySelector(`[data-g-set="${v}"]`).click(), v);
const setMode = (p, v) => p.evaluate(v => document.querySelector(`[data-m-set="${v}"]`).click(), v);
const setReq = (p, v) => p.evaluate(v => document.querySelector(`[data-r-set="${v}"]`).click(), v);
const setTool = (p, attr, v) => p.evaluate(([a, v]) => document.querySelector(`[data-${a}-set="${v}"]`).click(), [attr, v]);
const hideTools = p => p.evaluate(() => document.getElementById('tools').style.visibility = 'hidden');
const showTools = p => p.evaluate(() => document.getElementById('tools').style.visibility = '');
const reset = p => step(p, 'reset');

/* the walk, to the editor of an enriched, incomplete draft. Every check that needs that state calls this
   rather than repeating the steps, so a change to the walk cannot leave half the checks measuring a
   different page from the other half. */
/* ROUND 1'S CHECKS RUN IN MODE B, AND THAT IS ITSELF A ROUND-2 FINDING.
   Round 1 asks how the gate SPEAKS, which presupposes somewhere to speak. 074's top bar is `‹ · título ·
   CTA` and has no slot for a sentence — so G1's explanation is only buildable in B. Pinning the round-1
   checks to B keeps them measuring what they were written to measure; check 22 is where the dependency
   itself is asserted instead of being hidden by this convenience. */
async function toEditor(p, mode = 'B') {
  await reset(p);
  await setMode(p, mode);
  await setReq(p, 'R3');   /* round 3's baseline, so round 1/2 checks keep measuring their own question */
  await step(p, 'create'); await step(p, 'enriched'); await step(p, 'edit');
  /* THE SNACKBAR IS CLEARED HERE ON PURPOSE, AND CHECK 16 IS WHY IT IS NOT SWEPT UNDER THE RUG.
     d55's completion toast lives 10000ms and the walk reaches the editor about a second after it fires, so
     every check below would otherwise be measuring the gate THROUGH a toast that covers it — and check 11
     would be driving a button no finger could reach. Check 16 walks WITHOUT this line and asserts the
     collision, so the cost is counted rather than hidden by the convenience that makes the rest legible. */
  await clearSnack(p);
  /* the snackbar fades out over a transition; a screenshot taken immediately catches its GHOST superimposed
     on the bar, which is how the first clean-looking capture of this round still showed two overlapping
     sentences. Waiting out the transition is part of clearing it. */
  await p.waitForTimeout(260);
}
/* 077's lesson, reused: whatever is on screen after this can only have come from what happened next. */
const clearSnack = p => p.evaluate(() => document.getElementById('snack').classList.remove('show'));
/* the REAL button, not the walk's shortcut. `step(p,'publish')` calls doPublish() directly, which is how
   11d found that G1's gate lived only in the paint — but it also bypasses anything COVERING the button, so
   a check that only ever used it could not see check 16's collision. Both routes are used deliberately. */
const tapPublish = p => p.evaluate(() => { const b = document.getElementById('publish'); b && b.click(); });

const gateState = p => p.evaluate(() => {
  const b = document.getElementById('publish');
  const why = document.querySelector('#tbar .why, #stack .why, #savebar .why');
  const g = window.byId(window.S.editing);
  return {
    hasBtn: !!b,
    disabled: b ? b.disabled : null,
    why: why ? why.textContent.trim() : '',
    missing: g ? window.missing(g).map(m => m.k) : null,
    status: g ? g.status : null,
    units: g ? g.units : null,
    unitsRow: (document.querySelector('[data-field="units"] .fr-v') || {}).textContent || '',
    missDots: document.querySelectorAll('.frow .miss').length,
    missDotKeys: [...document.querySelectorAll('.frow')].filter(r => r.querySelector('.miss')).map(r => r.dataset.field),
    dialogOpen: document.getElementById('dscrim').classList.contains('open'),
    dialogText: document.getElementById('dlg-d').textContent.trim(),
    snack: document.getElementById('snack').classList.contains('show')
      ? document.getElementById('snack').querySelector('span').textContent.trim() : null
  };
});

(async () => {
  const exe = process.env.CHROME_BIN || '/usr/bin/google-chrome-stable';
  const browser = await chromium.launch(fs.existsSync(exe) ? { executablePath: exe } : {});
  const page = await browser.newPage({ viewport: { width: 375, height: 740 }, deviceScaleFactor: 2 });
  const errors = [];
  page.on('console', m => m.type() === 'error' && errors.push(m.text()));
  page.on('pageerror', e => errors.push(String(e)));
  await page.goto(URL, { waitUntil: 'networkidle' });

  const toSheet = async () => {
    await reset(page);
    await step(page, 'create'); await step(page, 'enriched'); await step(page, 'draft');
  };

  /* ---- 0. el panel se oculta de verdad, así cualquier hit-test significa algo ---- */
  await hideTools(page);
  ok(await page.evaluate(() => getComputedStyle(document.getElementById('tools')).visibility === 'hidden'),
    '0 · #tools se oculta de verdad antes de cualquier hit-test');
  await showTools(page);

  /* ---- 1. NO QUEDA NINGÚN TOGGLE DE VARIANTE ----
     072: *"lo que está en pantalla es la decisión, no un menú de decisiones."* El desarrollador lo pidió
     explícitamente. Asertado como ausencia para que no vuelvan de a uno. */
  const toggles = await page.evaluate(() => ({
    variantes: document.querySelectorAll('[data-v-set],[data-g-set],[data-m-set],[data-r-set],[data-exp-set],[data-nm-set],.vt').length,
    pasos: document.querySelectorAll('[data-walk]').length
  }));
  ok(toggles.variantes === 0, `1 · no queda ningún toggle de variante en la página (${toggles.variantes})`);

  /* ---- 2. la hoja se abre desde la LISTA, con UN solo botón, y la fila no lleva chevron (D-19i) ---- */
  await toSheet();
  const abierta = await page.evaluate(() => {
    const sh = document.getElementById('sheet');
    return { open: sh.classList.contains('open'), enLista: window.S.screen === 'juegos',
      botones: [...sh.querySelectorAll('.cta, .obtn, .btn')].map(b => b.textContent.trim()),
      chevEnFila: !!document.querySelector('.row[data-act="draft"] .chev') };
  });
  ok(abierta.open && abierta.enLista && abierta.botones.length === 1 && abierta.botones[0] === 'Publicar' && !abierta.chevEnFila,
    `2 · la hoja se abre sobre la LISTA, con UN solo botón (${JSON.stringify(abierta.botones)}) y la fila sin chevron`);

  /* ---- 3. P2, y el CTA más fuerte ----
     Muerto y vivo sobre LA MISMA hoja, y el muerto medido en color real: 064 prohibió los botones
     deshabilitados, así que este — que es deliberado — tiene que seguir siendo legible, no apagado. */
  await toSheet(); await hideTools(page);
  const muerto = await page.evaluate(() => {
    const b = document.getElementById('dpub'), cs = getComputedStyle(b), r = b.getBoundingClientRect();
    return { dis: b.disabled, bg: cs.backgroundColor, fg: cs.color, h: Math.round(r.height), w: Math.round(r.width),
      op: cs.opacity, err: !!document.getElementById('dband-e'),
      marca: (document.querySelector('.flabel .req') || {}).textContent || '' };
  });
  await showTools(page);
  await step(page, 'band'); await hideTools(page);
  const vivo = await page.evaluate(() => {
    const b = document.getElementById('dpub'), cs = getComputedStyle(b);
    return { dis: b.disabled, bg: cs.backgroundColor, fg: cs.color };
  });
  await showTools(page);
  ok(muerto.dis === true && vivo.dis === false && muerto.bg !== vivo.bg,
    `3a · P2 · el botón nace muerto y revive al elegir el nivel, y cambia de relleno (${muerto.bg} -> ${vivo.bg})`);
  ok(muerto.h >= 48 && muerto.w >= 300 && vivo.fg === 'rgb(255, 255, 255)',
    `3b · el CTA es fuerte: ${muerto.w}x${muerto.h}px, relleno, ancho completo`);
  ok(muerto.op === '1', `3c · y el estado muerto NO se dibuja con opacidad (${muerto.op}) — el texto sigue legible`);
  ok(muerto.err === false && /hace falta para publicar/.test(muerto.marca),
    `3d · P2 no da mensaje de error, así que la marca de la etiqueta es la ÚNICA explicación ("${muerto.marca.trim()}")`);

  /* ---- 4. nada se escribe hasta Publicar ---- */
  await toSheet();
  await page.evaluate(() => { const i = document.getElementById('dname'); i.value = 'Otro nombre';
    i.dispatchEvent(new Event('input', { bubbles: true })); });
  await page.evaluate(() => document.querySelector('.sh-x').click());
  const cancelado = await page.evaluate(() => { const g = window.byId(window.NEW); return { name: g.name, status: g.status }; });
  ok(cancelado.name === 'Hellas' && cancelado.status === 'draft',
    `4 · escribir y cancelar con el ✕ no deja rastro (${JSON.stringify(cancelado)})`);

  /* ---- 5. expansión: sin nivel, y NO PUEDE quedar con uno ----
     No es cosmético: `section_query(:weight_band)` (catalog.ex:851) filtra por banda y NO excluye
     expansiones, así que una expansión CON nivel aparecería en una fila de la web — justo lo que la regla
     del desarrollador prohíbe. El formulario no puede ofrecer ese estado. */
  await toSheet(); await step(page, 'band');
  const antes = await page.evaluate(() => window.DRAFT.weight_band);
  await step(page, 'exp');
  const despues = await page.evaluate(() => ({ band: window.DRAFT.weight_band, seg: !!document.querySelector('.seg'),
    dis: document.getElementById('dpub').disabled }));
  await step(page, 'pub');
  const pubExp = await page.evaluate(() => { const g = window.byId(window.NEW); return { st: g.status, band: g.weight_band, exp: g.is_expansion }; });
  ok(antes === 'ingenio_estratega' && despues.band === '' && despues.seg === false && despues.dis === false,
    `5a · marcar expansión borra el nivel, esconde el bloque y DESPIERTA el botón (${JSON.stringify(despues)})`);
  ok(pubExp.st === 'published' && pubExp.band === null && pubExp.exp === true,
    `5b · y publica sin nivel: no puede entrar en ninguna fila por banda (${JSON.stringify(pubExp)})`);
  ok(await page.evaluate(() => (document.querySelector('.row.fresh .pill-outline') || {}).textContent) === 'Expansión',
    '5c · y la fila de la ludoteca la marca con el pill informativo (d36/041)');

  /* ---- 6. las tres bandas reales ---- */
  await toSheet();
  const bandas = await page.evaluate(() => [...document.querySelectorAll('[data-band]')].map(b => b.dataset.band));
  ok(bandas.join() === 'descubre_el_hobby,ingenio_estratega,nivel_experto',
    `6 · la hoja ofrece las TRES bandas reales, no las cuatro inventadas (${JSON.stringify(bandas)})`);

  /* ---- 7. copias se pre-carga en 1 al publicar (el default que falta) ---- */
  await toSheet(); await step(page, 'band'); await step(page, 'pub');
  ok(await page.evaluate(() => window.byId(window.NEW).units) === 1,
    '7 · publicar pre-carga copias en 1 — `units` no tiene default en la base y enrichment nunca lo castea');

  /* ---- 8. publicar vuelve a la lista, scrollea y resalta ----
     076 (d55, d18-enmendada) ya decidió `.row.fresh` + `scrollNewIntoView()` al CREAR; esto es lo mismo al
     PUBLICAR. Medido con el rect Y con un hit test: una fila resaltada fuera de pantalla no es una pista. */
  await hideTools(page);
  const vuelta = await page.evaluate(() => {
    const row = document.querySelector('.row.fresh');
    const fold = document.querySelector('.tabs').getBoundingClientRect().top;
    const rr = row && row.getBoundingClientRect();
    return { pantalla: window.S.screen, hoja: document.getElementById('sheet').classList.contains('open'),
      st: window.byId(window.NEW).status, resaltada: !!row,
      visible: !!rr && rr.top >= 0 && rr.bottom <= fold, y: rr && Math.round(rr.top),
      /* RESUELTO POR ANCESTRÍA, no por la clase de la hoja del DOM: el punto dentro de la fila cae sobre
         su `<span class="txt">`, así que leer el elemento devolvía "txt" y el check se ponía rojo mientras
         la página hacía exactamente lo que se le pedía. Un hit-test tiene que nombrar el CONTENEDOR — es
         el mismo error que ya se corrigió una vez en esta suite. */
      hit: rr && rr.top >= 0
        ? (el => el ? (el.closest('.row') ? 'row' : el.id || el.className || el.tagName) : 'nada')
          (document.elementFromPoint(rr.left + rr.width / 2, rr.top + rr.height / 2))
        : 'fuera de pantalla' };
  });
  await page.screenshot({ path: path.join(OUT, 'lista-publicado.png') });
  await showTools(page);
  ok(vuelta.pantalla === 'juegos' && !vuelta.hoja && vuelta.st === 'published' && vuelta.resaltada
    && vuelta.visible && /row/.test(vuelta.hit || ''),
    `8 · publicar cierra la hoja, vuelve a la lista y deja la fila resaltada Y ALCANZABLE en y=${vuelta.y} (${JSON.stringify(vuelta)})`);

  /* ---- 9. el editor sólo se alcanza una vez publicado, y no ofrece publicar ---- */
  await step(page, 'edit');
  const editor = await page.evaluate(() => {
    const laid = id => { const e = document.getElementById(id); return !!(e && e.offsetParent); };
    return { hdr: laid('hdr'), tabs: laid('tabs'), tbar: laid('tbar'),
      acciones: [...document.querySelectorAll('#tbar .btn')].map(b => b.textContent.trim()),
      backs: [...document.querySelectorAll('.back, .tb-back')].filter(e => e.offsetParent).length,
      filas: document.querySelectorAll('.frow').length,
      chevs: [...document.querySelectorAll('.frow')].filter(r => r.querySelector('.chev')).length,
      ciclo: (document.querySelector('.gh-st') || {}).textContent };
  });
  ok(!editor.hdr && !editor.tabs && editor.tbar && editor.backs === 1
    && editor.acciones.length === 1 && editor.acciones[0] === 'Guardar',
    `9a · el editor es un destino a pantalla completa con la barra de 074 y UNA acción (${JSON.stringify(editor.acciones)})`);
  ok(editor.filas === 6 && editor.chevs === 0 && /^Publicado/.test(editor.ciclo || ''),
    `9b · seis filas de d33 sin chevron (D-19i) y el ciclo como punto + texto (${JSON.stringify(editor)})`);

  /* ---- 10. sin errores de consola ---- */
  ok(errors.length === 0, `10 · sin errores de consola${errors.length ? ' — ' + errors.slice(0, 2).join(' | ') : ''}`);

  /* ---- capturas ---- */
  await toSheet(); await hideTools(page);
  await page.evaluate(() => document.querySelector('.sheet').scrollTop = 0);
  await page.screenshot({ path: path.join(OUT, 'hoja-arriba.png') });
  await page.evaluate(() => document.querySelector('.sheet').scrollTop = 9999);
  await page.screenshot({ path: path.join(OUT, 'hoja-cta-muerto.png') });
  await showTools(page);
  await step(page, 'band'); await hideTools(page);
  await page.evaluate(() => document.querySelector('.sheet').scrollTop = 9999);
  await page.screenshot({ path: path.join(OUT, 'hoja-cta-vivo.png') });
  await showTools(page);

  console.log(log.join('\n'));
  const pass = log.filter(l => l.startsWith('PASS')).length;
  console.log(`\n${pass}/${log.length}  ·  capturas en ${OUT}`);
  await browser.close();
  process.exit(pass === log.length ? 0 : 1);
})();
