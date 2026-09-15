/* Headless-Chrome check for sketch 063 (final V2). Asserts layout rules from README "Winner: R8 V2" and exercises the editor flows.
   Run from the repo root:
     python3 -m http.server 8765 &            # serves the sketch (fonts/logo load via relative paths)
     node .planning/sketches/063-admin-game-editor/verify.js
   Env: PLAYWRIGHT_CORE=/path/to/node_modules/playwright-core (auto-detected from node_modules or the npx cache otherwise)
        SKETCH_URL (default http://127.0.0.1:8765/.planning/sketches/063-admin-game-editor/index.html)
        SHOTS_DIR  (default <os tmp>/sketch-063-shots) — screenshots for a visual pass (phone, band, dark, failed, desktop)
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
  const scrollTo = (sel, off) => J(([sel, off]) => { const sc = document.querySelector('.scroller'); sc.scrollTop = document.querySelector(sel).getBoundingClientRect().top - sc.getBoundingClientRect().top - off; }, [sel, off]);
  const lines = () => J(() => [...document.querySelectorAll('#main *')].filter(el => { const cs = getComputedStyle(el); return ['Top','Bottom','Left','Right'].some(sd => parseFloat(cs['border' + sd + 'Width']) > 0 && cs['border' + sd + 'Style'] !== 'none' && cs['border' + sd + 'Color'] !== 'rgba(0, 0, 0, 0)' && !el.matches('.obtn')); }).length);

  ok(await J(() => !document.querySelector('[data-v8],[data-nav7],[data-layout],[data-pen],[data-club],#intstrip,.v1-side,#segwrap')), 'single design, no variant switches or leftovers');
  for (const st of ['draft', 'published', 'retired']) {
    await click(`[data-status="${st}"]`); ok(!(await overflow()), `${st} phone no overflow`); ok((await lines()) === 0, `${st} no lines in body`);
    ok(await J(() => { const q = ['.thead', '.img6', '.dfield6', '.bgg6s', '.zone-int', '.club6', '.est6'].map(x => document.querySelector(x).getBoundingClientRect().top); return q.every((v, i) => !i || v >= q[i - 1]); }), `${st} order: título → portada → descripción → BGG → zona interna (club → estado)`);
    ok(await J(() => { const z = document.querySelector('.zone-int'); return z.contains(document.querySelector('.club6')) && z.contains(document.querySelector('.est6')) && !z.contains(document.querySelector('.bgg6s')); }), `${st} internal zone holds only club + estado`);
  }
  ok(await J(() => { const z = document.querySelector('.zone-int').getBoundingClientRect(), sc = document.querySelector('.scroller').getBoundingClientRect(); return Math.abs(z.left - sc.left) <= 1 && Math.abs(z.right - sc.right) <= 1; }), 'band full-bleed on phone');
  ok(await J(() => [...document.querySelectorAll('.sec-label')].map(l => getComputedStyle(l).font).every((f, i, a) => f === a[0])), 'section labels identical');
  await click('[data-status="published"]'); await shot('top'); await scrollTo('.zone-int', 260); await shot('band');
  // flows
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
  await p.fill('#ed-units', '0'); await click('#ebar [data-act="e-save"]'); ok(await J(() => !!E.errs.units && document.activeElement.id === 'ed-units'), 'units validation focuses field');
  await p.fill('#ed-units', '2'); await click('[data-act="e-back"]'); ok(await J(() => !!document.querySelector('#sheet-act.open')), 'leave guard'); await click('#sheet-act [data-act="e-leave-discard"]'); await click('[data-act="e-open"]');
  await click('[data-act="e-bgg-toggle"]'); ok(await J(() => document.querySelectorAll('.fcol').length === 4), 'BGG expands');
  await click('[data-bgg="failed"]'); ok(!(await overflow()), 'failed no overflow'); await shot('failed'); await click('[data-act="e-retry"]'); await wait(1800);
  // dark + desktop
  await J(() => document.documentElement.dataset.theme = 'dark'); await click('[data-status="published"]'); await scrollTo('.zone-int', 260); await shot('band-dark'); await J(() => delete document.documentElement.dataset.theme);
  await click('[data-vp="desk"]'); await click('[data-status="published"]'); ok(!(await overflow()), 'desk no overflow'); await shot('desk');
  await J(() => document.querySelector('.scroller').scrollTo(0, 99999)); await wait(150); await shot('desk-end');
  ok(await J(() => { const c = document.querySelector('.zone-int .club6').getBoundingClientRect(), e = document.querySelector('.zone-int .est6').getBoundingClientRect(); return e.left > c.right; }), 'desk: club | estado side by side in band');
  ok(errs.length === 0, 'no JS errors ' + errs.join(' | '));
  console.log(log.join('\n')); console.log(`\n${log.filter(l => l.startsWith('PASS')).length}/${log.length} passed · screenshots in ${OUT}`); await b.close();
  process.exitCode = log.some(l => l.startsWith('FAIL')) ? 1 : 0;
})().catch(e => { console.log(log.join('\n')); console.error('CRASH', e.message); process.exit(1); });
