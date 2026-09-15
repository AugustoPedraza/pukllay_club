/* Headless-Chrome check for sketch 063 (V2 + Ronda 9 refinements). Asserts layout rules from README "Winner: R8 V2" / "Round 9"
   and exercises the editor flows.
   Run from the repo root:
     python3 -m http.server 8765 &            # serves the sketch (fonts/logo load via relative paths)
     node .planning/sketches/063-admin-game-editor/verify.js
   Env: PLAYWRIGHT_CORE=/path/to/node_modules/playwright-core (auto-detected from node_modules or the npx cache otherwise)
        SKETCH_URL (default http://127.0.0.1:8765/.planning/sketches/063-admin-game-editor/index.html)
        SHOTS_DIR  (default <os tmp>/sketch-063-shots) — screenshots for a visual pass (phone per variant, dark, failed, desktop)
   Uses the system Chrome (channel: 'chrome'); no browser download needed. Prints PASS/FAIL per check; the /favicon.ico 404 is ignored. */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found: run `npx playwright --version` once, or set PLAYWRIGHT_CORE'); process.exit(2);
}
const { chromium } = loadPlaywright();
const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/063-admin-game-editor/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-063-shots'); fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);
(async () => {
  const b = await chromium.launch({ channel: 'chrome', headless: true });
  const p = await b.newPage({ viewport: { width: 1300, height: 1000 } });
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  p.on('console', m => m.type() === 'error' && !/404/.test(m.text()) && errs.push(m.text()));
  await p.goto(URL); await p.click('#tools-toggle');
  const J = (f, a) => p.evaluate(f, a), wait = ms => p.waitForTimeout(ms);
  const click = async sel => { await p.click(sel); await wait(350); };
  const overflow = () => J(() => { const s = document.querySelector('.scroller'); return s.scrollWidth > s.clientWidth + 1; });
  const shot = async n => (await p.$('#device')).screenshot({ path: `${OUT}/${n}.png` });
  const scrollTo = (sel, off) => J(([sel, off]) => { const sc = document.querySelector('.scroller'); sc.scrollTop += document.querySelector(sel).getBoundingClientRect().top - sc.getBoundingClientRect().top - off; }, [sel, off]);
  const lines = () => J(() => [...document.querySelectorAll('#main *')].filter(el => { const cs = getComputedStyle(el); return ['Top','Bottom','Left','Right'].some(sd => parseFloat(cs['border' + sd + 'Width']) > 0 && cs['border' + sd + 'Style'] !== 'none' && cs['border' + sd + 'Color'] !== 'rgba(0, 0, 0, 0)' && !el.matches('.obtn')); }).length);
  const noCopias = () => J(() => !/copia/i.test(document.getElementById('device').innerText + (document.getElementById('sheet-act')?.innerText || '')));
  const E = () => J(() => ({ status: E.status, units: +E.ed.units, filas: E.filas, u: E.unitsUi }));

  ok(await J(() => !document.querySelector('[data-v8],[data-nav7],[data-layout],[data-pen],[data-club],#intstrip,.v1-side,#segwrap,#ed-units')), 'no leftovers from earlier rounds; no typed units field');
  ok(await J(() => document.querySelectorAll('.stab[data-filas]').length === 3 && document.querySelectorAll('.stab[data-units]').length === 3), 'R9 switches: 3 Filas × 3 Unidades');

  /* layout per Filas variant × status (V2 rules, order gains .filas6 for F2/F3) */
  for (const f of ['f1', 'f2', 'f3']) {
    await click(`[data-filas="${f}"]`);
    for (const st of ['draft', 'published', 'retired']) {
      await click(`[data-status="${st}"]`);
      ok(!(await overflow()) && (await lines()) === 0, `${f} ${st}: no overflow, no lines`);
      ok(await J(f => { const seq = ['.thead', '.img6', '.dfield6', ...(f === 'f1' ? [] : ['.filas6']), '.bgg6s', '.zone-int', '.club6', '.est6'];
        const q = seq.map(x => document.querySelector(x)); if (q.some(x => !x)) return false; const t = q.map(x => x.getBoundingClientRect().top); return t.every((v, i) => !i || v >= t[i - 1]); }, f),
        `${f} ${st}: order título → portada → descripción${f === 'f1' ? '' : ' → en el inicio'} → BGG → zona interna (club → estado)`);
      ok(await J(f => { const z = document.querySelector('.zone-int'); const fil = document.querySelector('.filas6');
        return z.contains(document.querySelector('.club6')) && z.contains(document.querySelector('.est6')) && !z.contains(document.querySelector('.bgg6s')) && !(fil && z.contains(fil))
          && (f === 'f1' ? !!document.querySelector('.thead .tags-row') && !fil : !document.querySelector('.thead .tags-row')); }, f), `${f} ${st}: filas in one place only, in the public part`);
    }
    await click('[data-status="published"]'); await shot(`${f}-published-top`); if (f !== 'f1') { await scrollTo('.filas6', 120); await shot(`${f}-published-filas`); }
    await click('[data-status="retired"]'); if (f !== 'f1') { await scrollTo('.filas6', 120); } await shot(`${f}-retired-filas`);
    await click('[data-status="draft"]'); if (f !== 'f1') { await scrollTo('.filas6', 120); } await shot(`${f}-draft-filas`);
  }
  ok(await J(() => [...document.querySelectorAll('.sec-label')].map(l => getComputedStyle(l).font).every((f, i, a) => f === a[0])), 'section labels identical (incl. En el inicio)');
  ok(await J(() => { const z = document.querySelector('.zone-int').getBoundingClientRect(), sc = document.querySelector('.scroller').getBoundingClientRect(); return Math.abs(z.left - sc.left) <= 1 && Math.abs(z.right - sc.right) <= 1; }), 'band full-bleed on phone');

  /* Filas content */
  await click('[data-status="published"]'); await click('[data-filas="f1"]');
  ok(await J(() => { const t = document.querySelector('.thead .tags'); return t.querySelectorAll('.pk-pill-tag').length === 1 && [...t.querySelectorAll('.pk-pill-auto')].map(x => x.textContent.trim()).join('|') === 'Ingenio estratega|Recientemente añadidos'; }), 'F1: manual pill + automatic ✦ pills (level, recent)');
  await click('[data-status="draft"]'); ok(await J(() => /Al publicarlo/.test(document.querySelector('.thead .tags-lead').textContent)), 'F1: draft lead says rows apply on publish');
  await click('[data-filas="f2"]'); await click('[data-status="published"]');
  ok(await J(() => [...document.querySelectorAll('.filas6 .frow9:not(.add) .gname')].map(x => x.textContent).join('|') === 'Destacados del club|Ingenio estratega|Recientemente añadidos'), 'F2: one row per home row the game is in, in home order');
  ok(await J(() => { const r = [...document.querySelectorAll('.filas6 .frow9:not(.add)')]; return r[0].tagName === 'BUTTON' && r[1].tagName === 'DIV' && /cambia con el Nivel/.test(r[1].textContent); }), 'F2: manual rows editable (✎), automatic rows explain why');
  await click('[data-act="e-band-sheet"]'); await click('#sheet-act [data-v="e"]');
  ok(await J(() => /Nivel experto/.test(document.querySelector('.filas6').textContent) && !/Ingenio estratega/.test(document.querySelector('.filas6').textContent)), 'F2: changing Nivel moves the level row');
  await click('.filas6 .frow9.add'); await click('#sheet-act [data-sec="2"]'); await click('#sheet-act [data-act="e-close"]');
  ok(await J(() => /Crea conexiones/.test(document.querySelector('.filas6').textContent)), 'F2: Sumar a otra fila → switch adds the row');
  await click('[data-filas="f3"]'); await click('[data-status="published"]');
  ok(await J(() => document.querySelectorAll('.mh-row').length === 7 && document.querySelectorAll('.mh-row.in').length === 3 && document.querySelectorAll('.mh-rail i.me').length === 3), 'F3: all 7 home rows in order, 3 marked with the cover');
  ok(await J(() => { const cols = [...document.querySelectorAll('.mh-rail')].map(r => [...r.children].map(i => Math.round(i.getBoundingClientRect().left))); return cols.every(c => c.join() === cols[0].join()); }), 'F3: tile columns line up across rows (marked tile is taller, not wider)');
  await click('[data-status="retired"]');
  ok(await J(() => /retirado/i.test(document.querySelector('.filas6 .fnote').textContent) && /Duelos memorables/.test(document.querySelector('.mh-hidden')?.textContent || '')), 'F3: retired note + hidden row mentioned outside the home list');

  /* Unidades */
  const unitsFlows = async u => {
    await click(`[data-units="${u}"]`); await click('[data-status="draft"]'); await scrollTo('.zone-int', 200); await shot(`${u}-units`);
    ok(await noCopias(), `${u}: no "copia(s)" wording`);
  };
  await click('[data-filas="f1"]');
  await unitsFlows('u1');
  ok(await J(() => document.getElementById('u-dec').disabled && document.querySelector('.urow .stp-n').textContent === '1'), 'U1: shows 1, − disabled at 1');
  await click('#u-inc'); ok((await E()).units === 2 && await J(() => document.querySelector('#ebar .bl2').textContent === 'Cambios sin guardar' && document.activeElement.id === 'u-inc'), 'U1: + → 2, dirty, focus stays');
  await click('#u-dec'); ok((await E()).units === 1 && await J(() => document.activeElement.id === 'u-inc'), 'U1: − back to 1, focus moves to + when − disables');
  ok(await J(() => { const r = document.getElementById('u-inc').getBoundingClientRect(), d = document.getElementById('u-dec').getBoundingClientRect(); return r.width >= 32 && r.left - d.right >= 24; }), 'U1: 32px buttons with room for 44px hit areas');
  await unitsFlows('u2');
  ok(await J(() => document.querySelector('.useg .on').textContent === '1'), 'U2: 1 selected by default');
  await click('#u-set2'); ok((await E()).units === 2, 'U2: tap 2');
  await click('#u-set3'); ok((await E()).units === 3 && await J(() => !!document.querySelector('.useg .ustep.on .stp-n')), 'U2: Más → 3 with an inline stepper');
  await click('#u-inc'); ok((await E()).units === 4, 'U2: stepper + → 4'); await click('#u-dec'); await click('#u-dec');
  ok((await E()).units === 2 && await J(() => !document.querySelector('.ustep') && document.querySelector('.useg .on').textContent === '2'), 'U2: − below 3 folds back to the 2 segment');
  await scrollTo('.zone-int', 200); await shot('u2-units-2');
  await unitsFlows('u3');
  ok(await J(() => document.getElementById('units-val').textContent === '1 unidad' && !!document.querySelector('#u-open .pen')), 'U3: "1 unidad" value row with ✎');
  await click('#u-open'); ok(await J(() => /Lo más común/.test(document.querySelector('#sheet-act.open').textContent)), 'U3: sheet opens with 1 marked as the usual');
  await shot('u3-sheet');
  await click('#sheet-act [data-act="e-units-pick"][data-n="2"]'); ok(await J(() => document.getElementById('units-val').textContent === '2 unidades'), 'U3: pick 2 → "2 unidades"');
  await click('#u-open'); await click('#us-set3'); await click('#us-inc');
  ok((await E()).units === 4 && await J(() => document.querySelector('#sheet-act.open .umore .stp-n').textContent === '4'), 'U3: 3 o más → stepper in the sheet');
  await shot('u3-sheet-more'); await click('#sheet-act [data-act="e-close"]');
  await click('[data-units="u1"]');

  /* V2 flows (under F1 + U1) */
  await click('[data-status="draft"]'); await p.fill('#ed-name', 'Brass (ES)'); await wait(100);
  ok(await J(() => document.querySelector('#ebar .bl2').textContent === 'Cambios sin guardar'), 'dirty shows in Estado');
  await click('#ebar [data-act="e-publish"]'); await wait(900); ok(await J(() => E.status === 'published' && E.saved.name === 'Brass (ES)'), 'Publicar saves + publishes');
  await click('#snack .tbtn'); ok(await J(() => E.status === 'draft'), 'Deshacer');
  await click('[data-status="published"]'); await click('#ebar [data-act="e-retire-ask"]'); ok(await J(() => document.activeElement.dataset.act === 'e-close'), 'Retirar confirm, Cancelar focused');
  await click('#sheet-act [data-act="e-retire"]'); ok(await J(() => E.status === 'retired'), 'retired');
  await click('[data-act="e-band-sheet"]'); ok(await J(() => /sugiere/.test(document.querySelector('#sheet-act .sheet-text').textContent)), 'BGG suggestion in Nivel sheet'); await p.keyboard.press('Escape'); await wait(300);
  await click('[data-act="e-shelf-sheet"]'); await click('#sheet-act [data-v="3"]'); ok(await J(() => E.ed.shelf === 3), 'Estante pick');
  await click('[data-act="e-desc-edit"]'); await p.keyboard.type(' Fin.'); await click('.thead .tags-row'); await click('#sheet-act [data-act="e-close"]');
  ok(await J(() => document.querySelector('.desc-p').textContent.endsWith('Fin.')), 'description edit in place');
  await p.fill('#ed-name', ''); await click('#ebar [data-act="e-save"]'); ok(await J(() => !!E.errs.name && document.activeElement.id === 'ed-name'), 'name validation focuses field (units can no longer be invalid)');
  await p.fill('#ed-name', 'Brass: Birmingham'); await click('#u-inc'); await click('[data-act="e-back"]'); ok(await J(() => !!document.querySelector('#sheet-act.open')), 'leave guard'); await click('#sheet-act [data-act="e-leave-discard"]'); await click('[data-act="e-open"]');
  await click('[data-act="e-bgg-toggle"]'); ok(await J(() => document.querySelectorAll('.fcol').length === 4), 'BGG expands');
  await click('[data-bgg="failed"]'); ok(!(await overflow()), 'failed no overflow'); await shot('failed'); await click('[data-act="e-retry"]'); await wait(1800);

  /* dark + desktop */
  await J(() => document.documentElement.dataset.theme = 'dark');
  await click('[data-status="published"]');
  for (const [f, u] of [['f2', 'u2'], ['f3', 'u3'], ['f1', 'u1']]) {
    await click(`[data-filas="${f}"]`); await click(`[data-units="${u}"]`); await click('[data-status="published"]');
    if (f !== 'f1') { await scrollTo('.filas6', 120); await shot(`dark-${f}`); }
    await scrollTo('.zone-int', 200); await shot(`dark-${u}`);
  }
  await J(() => delete document.documentElement.dataset.theme);
  await click('[data-vp="desk"]');
  for (const f of ['f1', 'f2', 'f3']) {
    await click(`[data-filas="${f}"]`); await click('[data-status="published"]'); ok(!(await overflow()), `desk ${f} no overflow`); await shot(`desk-${f}`);
    if (f !== 'f1') ok(await J(() => { const t = document.querySelector('.mast .tcol'); return t.contains(document.querySelector('.filas6')); }), `desk ${f}: En el inicio in the right column under Descripción`);
  }
  await J(() => document.querySelector('.scroller').scrollTo(0, 99999)); await wait(150); await shot('desk-end');
  ok(await J(() => { const c = document.querySelector('.zone-int .club6').getBoundingClientRect(), e = document.querySelector('.zone-int .est6').getBoundingClientRect(); return e.left > c.right; }), 'desk: club | estado side by side in band');
  ok(errs.length === 0, 'no JS errors ' + errs.join(' | '));
  console.log(log.join('\n')); console.log(`\n${log.filter(l => l.startsWith('PASS')).length}/${log.length} passed · screenshots in ${OUT}`); await b.close();
  process.exitCode = log.some(l => l.startsWith('FAIL')) ? 1 : 0;
})().catch(e => { console.log(log.join('\n')); console.error('CRASH', e.message); process.exit(1); });
