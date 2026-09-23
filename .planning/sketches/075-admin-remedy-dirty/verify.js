/* Checks de Chrome headless para el sketch 075 RONDA 4 — el remedio, sobre el chrome que la 079 y la
   080 dejaron decidido.
     python3 -m http.server 8765 &
     node .planning/sketches/075-admin-remedy-dirty/verify.js
   Env: PLAYWRIGHT_CORE, CHROME_BIN, SKETCH_URL, SHOTS_DIR.

   LA RONDA MIDE UN CAMBIO DE PREMISA, no una preferencia. Las rondas 1-3 preguntaron dónde vive el
   remedio MIENTRAS ESTÁ SUCIO, porque el único slot de CTA se lo llevaba `Guardar`. Ese slot ya no
   existe: la 079 dejó la barra en `‹ · título · ⋮` y la 080 bajó `Guardar` a una barra fija al pie.
   Así que el remedio no está desplazado — no tiene lugar en NINGUNA parte del chrome, limpio o
   sucio. Los checks 1-4 asientan eso para que no se pueda leer como una opinión. */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();

/* decodificador PNG mínimo, traído de la 079/080: el check 14 necesita un NÚMERO de tinta y el 13
   un diff. Comparar bytes de PNG no sirve — la compresión reescribe el stream con 1px de corrimiento. */
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
function diffPx(A, B) {
  if (A.w !== B.w || A.h !== B.h) return { diff: -1, max: -1 };
  let n = 0, mx = 0;
  for (let i = 0; i < A.w * A.h; i++) {
    let d = 0;
    for (let k = 0; k < 3; k++) d = Math.max(d, Math.abs(A.data[i * A.bpp + k] - B.data[i * B.bpp + k]));
    if (d > 2) n++; if (d > mx) mx = d;
  }
  return { diff: n, max: mx };
}

const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/075-admin-remedy-dirty/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-075-r4-shots');
fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);
/* el `#vnav` mide 44 con sus tres botones a 375; la ventana se pide más alta para que «375×667» sea
   un device de 667 REALES. El número se re-mide cada vez que cambia la cantidad de variantes — fue
   el defecto que la 080 encontró dos veces. */
const VN = 44;

/* ---------- la sonda ----------
   Todo lo que se lee se lee del DOM vivo y se HIT-TESTEA. La 075 ronda 1 casi le da la victoria a
   una variante por medir el pliegue contra el rect del scroller en vez de contra lo que tapa la
   pantalla; acá el remedio se cuenta como alcanzable sólo si `elementFromPoint` sobre su centro
   devuelve el propio botón. */
const probe = () => {
  const devEl = document.querySelector('.device'), dev = devEl.getBoundingClientRect();
  const at = (x, y) => { const e = document.elementFromPoint(x, y); if (!e) return null;
    const b = e.closest('button'); return b ? (b.id || (typeof b.className === 'string' ? b.className : '?')) : ('no-boton:' + e.tagName); };
  const isRemedy = el => !!el && (el.classList.contains('rmd') || el.id === 'stbtn');
  /* el remedio puede ser un `.rmd` (botón entendido, en el cuerpo o en el pie) o el bloque entero
     (`#stbtn`). Se cuentan LOS DOS con una sola regla: si se contara sólo `.rmd`, la banda daría 0
     y el check se leería como «la variante no tiene remedio» en vez de «no lo estoy midiendo». */
  const nodes = [...document.querySelectorAll('.rmd, #stbtn')].filter(e => e.offsetParent || e.id === 'stbtn');
  const bar = document.querySelector('#ctabar');
  const barTop = (bar && !bar.hidden) ? bar.getBoundingClientRect().top : dev.bottom;
  const measure = el => {
    const r = el.getBoundingClientRect();
    const cx = r.left + r.width / 2, cy = r.top + r.height / 2;
    const hitEl = document.elementFromPoint(cx, cy);
    return {
      cls: el.id || el.className, t: +(r.top - dev.top).toFixed(1), b: +(r.bottom - dev.top).toFixed(1),
      l: +(r.left - dev.left).toFixed(1), w: +r.width.toFixed(1), h: +r.height.toFixed(1),
      area: Math.round(r.width * r.height),
      /* «visible» es contra lo que TAPA la pantalla (el borde superior de la barra fija), no contra
         el alto del scroller. Ésa es la corrección que la ronda 1 tuvo que hacerse a sí misma. */
      visible: r.top >= dev.top && r.bottom <= barTop + 0.5,
      tappable: !!(hitEl && isRemedy(hitEl.closest('.rmd, #stbtn'))),
      hit: at(cx, cy)
    };
  };
  const note = document.querySelector('.note'), st = document.querySelector('.st');
  const cta = document.querySelector('#ctabar .cta');
  const nivel = document.querySelector('[data-edit="band"]');
  const paint = el => { if (!el) return 0; const cs = getComputedStyle(el);
    const bw = parseFloat(cs.borderTopWidth) || 0; if (!bw) return 0;
    const r = el.getBoundingClientRect();
    /* el área PINTADA de un contorno: el anillo, no la caja. Es la métrica que la 075 usó para la
       inversión de jerarquía, reusada acá tal cual para que los números sean comparables. */
    return Math.round(r.width * r.height - Math.max(0, r.width - 2 * bw) * Math.max(0, r.height - 2 * bw)); };
  return {
    home: (document.querySelector('#vnav .on') || {}).dataset?.home || null,
    tbarBtns: [...document.querySelectorAll('.tbar button')].map(b => b.id || b.className),
    remedies: nodes.map(measure),
    n: nodes.length,
    diag: st ? st.innerText.replace(/\s+/g, ' ').trim() : null,
    diagName: st ? (st.getAttribute('aria-label') || st.innerText.replace(/\s+/g, ' ').trim()) : null,
    noteTxt: note ? note.innerText.replace(/\s+/g, ' ').trim() : null,
    noteB: note ? +(note.getBoundingClientRect().bottom - dev.top).toFixed(1) : null,
    stT: st ? +(st.getBoundingClientRect().top - dev.top).toFixed(1) : null,
    cta: cta ? { txt: cta.textContent.trim(), dis: cta.disabled, paint: paint(cta),
      right: +(document.querySelector('#ctabar').getBoundingClientRect().right - cta.getBoundingClientRect().right).toFixed(1) } : null,
    rmdPaint: paint(document.querySelector('#ctabar .rmd') || document.querySelector('#main .rmd')),
    rmdBorder: (() => { const e = document.querySelector('.rmd'); return e ? getComputedStyle(e).borderTopStyle : null; })(),
    /* el `<svg>` existe siempre; lo que faltaba era el `<path>` de adentro. Se cuenta el path. */
    rmdPaths: document.querySelectorAll('.rmd svg path').length,
    nivel: nivel ? { txt: nivel.innerText.replace(/\s+/g, ' ').trim(), on: !!nivel.offsetParent } : null,
    scMax: (() => { const sc = document.querySelector('#scroller'); return +(sc.scrollHeight - sc.clientHeight).toFixed(0); })()
  };
};

const setHome = h => document.querySelector(`#vnav [data-home="${h}"]`).click();
const setForm = f => document.querySelector(`#tools [data-form="${f}"]`).click();
const setSt = s => document.querySelector(`#tools [data-st="${s}"]`).click();
const hideTools = () => { document.querySelector('#tools').style.display = 'none';
  document.querySelector('#vnav').style.visibility = 'hidden'; };
/* ensuciar: se toca la fila `Es una expansión` y se elige la otra opción. Es la misma edición que
   usaron las rondas 1-3, para que los números se puedan comparar con los de aquellas. */
const soil = () => document.querySelector('[data-edit="exp"]').click();
const pickOther = () => { const o = [...document.querySelectorAll('.sheet .opt')];
  const cur = o.find(x => x.querySelector('.tick')); (o.find(x => x !== cur) || o[0]).click(); };

const BROKEN = ['no_bgg_id', 'bgg_missing'];

(async () => {
  const browser = await chromium.launch({ executablePath: process.env.CHROME_BIN || '/usr/bin/google-chrome', args: ['--no-sandbox'] });
  const page = await browser.newPage({ viewport: { width: 375, height: 667 + VN }, deviceScaleFactor: 2 });
  const errs = []; page.on('pageerror', e => errs.push(String(e)));
  page.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
  await page.goto(URL, { waitUntil: 'networkidle' });
  await page.evaluate(hideTools);

  const shot = async name => { await page.screenshot({ path: path.join(OUT, name + '.png') }); };
  /* EL SCROLL SE RESETEA EN CADA CASO, y eso es un check que se le debe al harness, no una
     comodidad: sin esto el primer caso limpio de cada bloque heredaba el `scrollTop` del último caso
     del bloque anterior (que termina midiendo el fondo), el diagnóstico quedaba fuera de pantalla y
     el hit-test devolvía «no alcanzable» — sobre una variante donde SÍ lo es. Un estado arrastrado
     entre casos es la forma más barata de fabricar un hallazgo. */
  const go = async (home, st, form, dirty) => {
    await page.evaluate(() => { document.querySelector('#scroller').scrollTop = 0; });
    await page.evaluate(setHome, home);
    await page.evaluate(setSt, st);
    if (form) await page.evaluate(setForm, form);
    if (dirty) { await page.evaluate(soil); await page.waitForTimeout(80);
      await page.evaluate(pickOther); await page.waitForTimeout(220); }
    return page.evaluate(probe);
  };

  /* ================= LA PREMISA ================= */
  {
    const p = await go('none', 'no_bgg_id', 'banda', false);
    ok(p.tbarBtns.length === 2 && /tb-back/.test(p.tbarBtns[0]) && /kebab/.test(p.tbarBtns[1]),
      `1  la barra de arriba NO tiene slot de CTA: ${p.tbarBtns.length} controles (${p.tbarBtns.join(' · ')}) — la premisa de las rondas 1-3 ya no existe`);
    ok(p.cta && p.cta.txt === 'Guardar' && p.cta.dis,
      `2  \`Guardar\` vive al pie y está apagado en limpio (${p.cta && p.cta.txt}, dis=${p.cta && p.cta.dis}) — nunca desplaza al remedio`);
  }

  /* 3 · el número de la ronda: EL REMEDIO NO ESTÁ EN NINGUNA PARTE, limpio Y sucio, a los dos
     extremos del scroll. Es la combinación que el check 27 de la ronda 3 declaró «no debe salir» —
     y es lo que sale hoy. */
  {
    const rows = [];
    for (const st of BROKEN) for (const d of [false, true]) {
      const p = await go('none', st, 'banda', d);
      await page.evaluate(() => { const s = document.querySelector('#scroller'); s.scrollTop = s.scrollHeight; });
      await page.waitForTimeout(120);
      const pb = await page.evaluate(probe);
      rows.push({ st, d, rest: p.n, bottom: pb.n, diag: p.diag });
    }
    const total = rows.reduce((a, r) => a + r.rest + r.bottom, 0);
    ok(total === 0, `3  HOME=none · el remedio no está: ${rows.map(r => `${r.st}/${r.d ? 'sucio' : 'limpio'} ${r.rest}+${r.bottom}`).join(' · ')} = ${total} en 4 situaciones × 2 extremos de scroll`);
    const acusa = rows.every(r => /Se está viendo así en la web/.test(r.diag));
    ok(acusa, `4  …y la acusación sigue ahí, palabra por palabra, en las 4: «Se está viendo así en la web»`);
  }

  /* ================= A · EL CUERPO ================= */
  {
    const rows = [];
    for (const st of BROKEN) for (const d of [false, true]) {
      const p = await go('body', st, 'banda', d);
      rows.push({ st, d, n: p.n, vis: p.remedies[0] && p.remedies[0].visible, tap: p.remedies[0] && p.remedies[0].tappable, r: p.remedies[0] });
    }
    ok(rows.every(r => r.n === 1 && r.vis && r.tap),
      `5  A · alcanzable 4 de 4, visible y hit-testeado: ${rows.map(r => `${r.st}/${r.d ? 'sucio' : 'limpio'} ${r.tap ? '✓' : '✗'}`).join(' · ')}`);
    const clean = rows.find(r => r.st === 'no_bgg_id' && !r.d).r, dirty = rows.find(r => r.st === 'no_bgg_id' && r.d).r;
    const travelA = Math.round(Math.abs(clean.l - dirty.l)) + Math.round(Math.abs(clean.t - dirty.t));

    /* ---- EL VIAJE SE ATRIBUYE, NO SE COBRA A OJO ----
       A viaja 18px al empezar la edición. La pregunta que decide si eso es un costo DE A o del chrome
       es de dónde salen esos 18px: la nota de la 080 pasa de una línea a dos al ensuciarse («Sin
       guardar · Tus cambios todavía no están en la web.») y empuja todo lo que tiene debajo. Si el
       número coincide con lo que crece la nota, el viaje no es del remedio: le pasa a la ficha entera,
       y A simplemente está adentro de ella. Cobrárselo a A sería rankear por un efecto de mi dibujo. */
    const grow = await page.evaluate(async () => {
      const h = () => document.querySelector('.note').getBoundingClientRect().height;
      document.querySelector('#scroller').scrollTop = 0;
      document.querySelector('#tools [data-st="no_bgg_id"]').click();
      const a = h();
      document.querySelector('[data-edit="exp"]').click();
      await new Promise(r => setTimeout(r, 80));
      const o = [...document.querySelectorAll('.sheet .opt')];
      (o.find(x => !x.querySelector('.tick')) || o[0]).click();
      await new Promise(r => setTimeout(r, 220));
      return { clean: +a.toFixed(1), dirty: +h().toFixed(1) };
    });
    const noteGrow = Math.round(grow.dirty - grow.clean);
    ok(travelA === noteGrow && noteGrow > 0,
      `6  A · viaja ${travelA}px al empezar la edición, y son EXACTAMENTE los ${noteGrow}px que crece la nota de la 080 al pasar a dos renglones (${grow.clean}→${grow.dirty}) — le pasa a la ficha entera, no al remedio`);
    /* el número de la ronda 2 era 24.535px² sobre una página con otras quillas; el de acá es el que
       hay. Se compara contra el botón entendido de la MISMA página, que es la comparación honesta. */
    const btn = await go('body', 'no_bgg_id', 'boton', false);
    const bArea = btn.remedies[0].area;
    ok(clean.area > bArea * 3,
      `7  A · banda · el control es el bloque entero: ${clean.w}×${clean.h} = ${clean.area}px², ${(clean.area / bArea).toFixed(1)}× el botón entendido de la misma página (${bArea}px²)`);
  }

  /* 8 · la banda, negativo: sin `.band` la variante vuelve a ser INDISTINGUIBLE de no hacer nada.
     Es el resultado que la ronda 2 obtuvo dibujando la V4 pura (diffPx 0 of 270000), re-corrido
     sobre el chrome nuevo. Si alguna vez da distinto de 0, la banda dejó de ser lo único que pinta. */
  {
    const pn = await go('none', 'no_bgg_id', 'banda', false);
    const geoNone = await page.evaluate(() => { const e = document.querySelector('.st'), r = e.getBoundingClientRect();
      const f = document.querySelector('.masthead').getBoundingClientRect();
      return { h: +r.height.toFixed(1), fichaT: +f.top.toFixed(1) }; });
    const a = decodePNG(await page.screenshot());
    await go('body', 'no_bgg_id', 'banda', false);
    const geoBody = await page.evaluate(() => { const e = document.querySelector('.st'), r = e.getBoundingClientRect();
      const f = document.querySelector('.masthead').getBoundingClientRect();
      return { h: +r.height.toFixed(1), fichaT: +f.top.toFixed(1) }; });
    const b = decodePNG(await page.screenshot());
    const withBand = diffPx(a, b);
    /* LA GEOMETRÍA PRIMERO. La ronda 2 perdió una medición leyendo un diff sobre dos páginas que no
       estaban alineadas: el diff reportaba pintura donde sólo había 8px de corrimiento. */
    ok(geoNone.h === geoBody.h && geoNone.fichaT === geoBody.fichaT,
      `8a la geometría es idéntica ANTES de leer un solo píxel: bloque ${geoNone.h}=${geoBody.h}, ficha y=${geoNone.fichaT}=${geoBody.fichaT}`);
    await page.addStyleTag({ content: '.st.tap.band::before { background: transparent !important; }' });
    const c = decodePNG(await page.screenshot());
    const without = diffPx(a, c);
    ok(withBand.diff > 0, `8b A · banda · con la banda SÍ se distingue de no hacer nada: ${withBand.diff}px de diferencia`);
    ok(without.diff === 0, `8c …y sin ella vuelve a ser idéntica: ${without.diff}px (la V4 pura de la ronda 2, re-medida sobre el chrome nuevo)`);
    await page.reload({ waitUntil: 'networkidle' }); await page.evaluate(hideTools);
  }

  /* 9 · el nombre accesible lleva el diagnóstico COMPLETO y la acción. Un aria-label con sólo el
     verbo le escondería a la asistencia el único texto que este bloque existe para dar. */
  {
    await go('body', 'no_bgg_id', 'banda', false);
    const name = await page.evaluate(() => document.querySelector('#stbtn').innerText.replace(/\s+/g, ' ').trim()
      + ' ' + (document.querySelector('#stbtn .sr') || {}).textContent);
    ok(/no está vinculado/.test(name) && /vincular/i.test(name),
      `9  A · el nombre accesible lleva las dos mitades: diagnóstico + acción`);
  }

  /* 10-11 · A · botón (la V2 de la ronda 1) */
  {
    const p = await go('body', 'no_bgg_id', 'boton', false);
    ok(p.rmdBorder === 'solid', `10 A · botón · el borde es \`solid\`, no el bisel \`outset\` que el UA pinta solo (${p.rmdBorder}) — lo que la 075 encontró en su primera captura`);
    ok(p.rmdPaths > 0, `11 …y el ícono tiene \`<path>\` adentro: ${p.rmdPaths} — el \`<svg>\` vacío con \`undefined\` que la 080 ya había documentado con \`tick\``);
  }

  /* ================= B · EL PIE ================= */
  {
    const rows = [];
    for (const st of BROKEN) for (const d of [false, true]) {
      const p = await go('foot', st, 'banda', d);
      await page.evaluate(() => { const s = document.querySelector('#scroller'); s.scrollTop = s.scrollHeight; });
      await page.waitForTimeout(120);
      const pb = await page.evaluate(probe);
      rows.push({ st, d, rest: p.remedies[0], bottom: pb.remedies[0] });
    }
    ok(rows.every(r => r.rest && r.rest.tappable && r.bottom && r.bottom.tappable),
      `12 B · alcanzable 4 de 4 a los DOS extremos del scroll: es chrome fijo, no se va nunca`);
    const a = rows[0].rest, b = rows[0].bottom;
    ok(a.t === b.t, `13 B · no se mueve con el scroll: y=${a.t} arriba, y=${b.t} al fondo`);
    /* y tampoco viaja al ensuciarse, que es el otro lado del check 6: la nota crece adentro del
       cuerpo y el pie ni se entera. Es la única ventaja medible que B le saca a A. */
    const bc = rows.find(r => r.st === 'no_bgg_id' && !r.d), bd = rows.find(r => r.st === 'no_bgg_id' && r.d);
    ok(bc.rest.t === bd.rest.t, `13b B · ni al empezar la edición: y=${bc.rest.t} limpio, y=${bd.rest.t} sucio — contra los 18px de A`);
  }

  /* 14 · EL COSTO NUEVO DE B, que ninguna ronda anterior podía tener: el pie pasa a llevar DOS
     controles con el mismo tratamiento (contorno A1 de 064), y en limpio el de la derecha está
     APAGADO mientras el de la izquierda está vivo. Es la inversión de la ronda 1 otra vez, en otro
     contenedor: el primario es el que no se puede tocar. */
  {
    const p = await go('foot', 'no_bgg_id', 'banda', false);
    ok(p.cta.dis && p.rmdPaint > 0,
      `14 B · limpio · el pie lleva un \`Guardar\` APAGADO (${p.cta.paint}px² de contorno) junto a un \`Vincular\` vivo (${p.rmdPaint}px²) — el primario es el que no se puede tocar`);
    ok(Math.abs(p.cta.right - 14) < 2, `15 B · \`Guardar\` conserva la quilla de 14 que fijó la 080: ${p.cta.right}px`);
  }

  /* ================= LO QUE VALE PARA LAS TRES ================= */
  /* 16 · la duplicación que las rondas 1-3 le cobraron a la V3 y a la V4 (alcanzable dos veces en
     limpio) es CERO acá, y no por una decisión: no hay un segundo lugar donde pueda estar. */
  {
    const counts = [];
    for (const h of ['body', 'foot']) for (const st of BROKEN) for (const d of [false, true]) {
      const p = await go(h, st, 'banda', d); counts.push(p.n);
    }
    ok(counts.every(c => c === 1), `16 el remedio está EXACTAMENTE una vez en A y en B, limpio y sucio: [${counts.join(',')}] — la duplicación que las rondas 2 y 3 cobraron es 0 por construcción`);
  }

  /* 17 · el defecto que encontró la captura y ningún check: `Nivel` es un campo DEL CLUB y se había
     ido con el bloque de BGG. */
  {
    const rows = [];
    for (const st of BROKEN.concat(['pending'])) { const p = await go('none', st, 'banda', false); rows.push([st, p.nivel]); }
    ok(rows.every(([, n]) => n && n.on), `17 \`Nivel\` sigue en la página en los juegos rotos: ${rows.map(([s, n]) => `${s} «${n && n.txt}»`).join(' · ')} — es del club, no de BGG`);
  }

  /* 18 · LA COLISIÓN QUE EL PORT DESTAPA, y que no es de ninguna de las dos decisiones por separado:
     la nota de la 080 y el diagnóstico de la 073/075 dicen la misma frase, con signos opuestos. */
  {
    const p = await go('none', 'no_bgg_id', 'banda', false);
    const both = /Así se ve en la web/.test(p.noteTxt) && /Se está viendo así en la web/.test(p.diag);
    const gap = +(p.stT - p.noteB).toFixed(1);
    ok(both, `18 la nota dice «Así se ve en la web.» y el diagnóstico «Se está viendo así en la web.» a ${gap}px una de otra — la misma frase tranquilizando y acusando`);
  }

  /* 19 · EL DEFECTO DE LA RONDA 1, NEGATIVO: vincular estando sucio NO puede borrar la edición del
     club. Se reproduce primero la versión vieja para confirmar que el check sabe verlo. */
  {
    await go('body', 'no_bgg_id', 'banda', true);
    const before = await page.evaluate(() => G.is_expansion);
    await page.evaluate(() => document.querySelector('#stbtn').click());
    await page.waitForTimeout(150);
    await page.evaluate(() => { document.querySelector('#s-bgg').value = '224517'; });
    await page.evaluate(() => document.querySelector('[data-act="commit-bgg"]').click());
    await page.waitForTimeout(200);
    const after = await page.evaluate(() => ({ exp: G.is_expansion, id: G.bgg_id, st: ST }));
    ok(before === true && after.exp === true && after.id === 224517,
      `19 vincular estando sucio NO borra la edición: \`is_expansion\` ${before} → ${after.exp}, y el id entró (${after.id}) — el defecto que la ronda 1 encontró en la 074`);
    const wiped = await page.evaluate(() => { /* la versión vieja: recargar el juego entero al commitear */
      G.is_expansion = true; loadState('no_bgg_id'); return G.is_expansion; });
    ok(wiped === false, `20 …y el check sabe verlo: reproducir la versión vieja (recargar al commitear) sí lo borra (${wiped})`);
    await page.reload({ waitUntil: 'networkidle' }); await page.evaluate(hideTools);
  }

  /* ================= CAPTURAS ================= */
  for (const [h, f, d, name] of [['none', 'banda', false, '1-hoy-limpio'], ['none', 'banda', true, '2-hoy-sucio'],
    ['body', 'banda', false, '3-cuerpo-banda'], ['body', 'boton', false, '4-cuerpo-boton'],
    ['foot', 'banda', false, '5-pie-limpio'], ['foot', 'banda', true, '6-pie-sucio']]) {
    await go(h, 'no_bgg_id', f, d); await shot(name);
  }
  /* 360×640, el chico real, y oscuro */
  await page.setViewportSize({ width: 360, height: 640 + VN });
  const small = await go('body', 'no_bgg_id', 'banda', false);
  ok(small.remedies[0] && small.remedies[0].visible && small.remedies[0].tappable,
    `21 360×640 · A sigue visible y tappable (y=${small.remedies[0] && small.remedies[0].t})`);
  await shot('7-360-cuerpo');
  await page.evaluate(() => document.documentElement.setAttribute('data-theme', 'dark'));
  const dark = await go('foot', 'no_bgg_id', 'banda', false);
  ok(dark.rmdPaint > 0, `22 oscuro · el contorno del remedio sigue pintando (${dark.rmdPaint}px²)`);
  await shot('8-oscuro-pie');

  ok(errs.length === 0, `23 sin errores de consola: ${errs.length ? errs.join(' | ') : 'ninguno'}`);

  console.log(log.join('\n'));
  const pass = log.filter(l => l.startsWith('PASS')).length;
  console.log(`\n${pass}/${log.length}   capturas en ${OUT}`);
  await browser.close();
  if (pass !== log.length) process.exitCode = 1;
})();
