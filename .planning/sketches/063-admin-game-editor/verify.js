/* Headless-Chrome check for sketch 063 (V2 + R9 F2/U2 + R10 D1 + R11 type + R12 C2/B3 + Ronda 13 BGG preview). Asserts layout rules from README "Winner: R8 V2",
   "Round 9"–"Round 13", and exercises the editor flows.
   Run from the repo root:
     python3 -m http.server 8765 &            # serves the sketch (fonts/logo load via relative paths)
     node .planning/sketches/063-admin-game-editor/verify.js
   Env: PLAYWRIGHT_CORE=/path/to/node_modules/playwright-core (auto-detected from node_modules or the npx cache otherwise)
        SKETCH_URL (default http://127.0.0.1:8765/.planning/sketches/063-admin-game-editor/index.html)
        SHOTS_DIR  (default <os tmp>/sketch-063-shots) — screenshots for a visual pass (phone En el inicio + BGG closed/open, dark, failed, desktop)
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
  /* decorative borders are still banned in the page body; 064's outlined buttons (.obtn/.b-pri/.b-sec) are controls, not lines; the R10 divider is a 1px background (.zl) */
  const lines = () => J(() => [...document.querySelectorAll('#main *')].filter(el => { const cs = getComputedStyle(el); return ['Top','Bottom','Left','Right'].some(sd => parseFloat(cs['border' + sd + 'Width']) > 0 && cs['border' + sd + 'Style'] !== 'none' && cs['border' + sd + 'Color'] !== 'rgba(0, 0, 0, 0)' && !el.matches('.obtn, .b-pri, .b-sec')); }).length);
  const noCopias = () => J(() => !/copia/i.test(document.getElementById('device').innerText));
  const units = () => J(() => +E.ed.units);

  ok(await J(() => !document.querySelector('[data-v8],[data-nav7],[data-layout],[data-pen],[data-club],#intstrip,.v1-side,#segwrap,#ed-units,[data-filas],[data-units],.mh-list,.pk-pill-auto,.thead .tags-row,#u-open,[data-div],.zone-int.band,.zone-cap,.ghead,[data-cta],[data-bggui],.sec-act,.cta3,.bgg-toggle,.lock6')), 'no leftovers (earlier rounds, F1/F3, U1/U3, D0/D2/D3, C1/C3, B1/B2)');
  ok(await J(() => document.querySelectorAll('#state-nav .var-nav').length === 2), 'single design: the top bar switches Estado only');
  /* 064 button system in Estado: roles per state, Guardar only with changes, nothing disabled */
  const estado = () => J(() => [...document.querySelectorAll('#ebar .eactions button')].map(b => (b.matches('.obtn,.b-pri') ? 'pri' : b.matches('.b-sec') ? 'sec' : b.matches('.danger') ? 'dan' : 'ter') + ':' + b.textContent.trim()).join(','));
  const matrix = [];
  for (const st of ['draft', 'published', 'retired']) {
    await click(`[data-status="${st}"]`); matrix.push(await estado());
    await click('#u-set' + (st === 'draft' ? 2 : 1)); matrix.push(await estado());
  }
  ok(matrix.join(' / ') === 'pri:Publicar / sec:Guardar,pri:Publicar / dan:Retirar de la web / dan:Retirar,pri:Guardar / sec:Restaurar / sec:Restaurar,pri:Guardar', '064 Estado matrix: ' + matrix.join(' / '));
  ok(await J(() => ![...document.querySelectorAll('#device button')].some(b => b.disabled && !b.closest('.sheet:not(.open)'))), '064: no disabled buttons on the page');
  ok(await J(() => { const b = document.querySelector('#ebar'); const s = b.querySelector('.bst').getBoundingClientRect(), a = b.querySelector('.eactions').getBoundingClientRect(); return a.top >= s.bottom; }), '064: Estado status on top, actions row below');

  /* layout per status (D1 divider is the only one) */
  for (const st of ['draft', 'published', 'retired']) {
    await click(`[data-status="${st}"]`);
    ok(!(await overflow()) && (await lines()) === 0, `${st}: no overflow, no border lines`);
    ok(await J(() => { const q = ['.thead', '.img6', '.dfield6', '.filas6', '.bgg6s', '.zone-int', '.club6', '.est6'].map(x => document.querySelector(x)); if (q.some(x => !x)) return false; const t = q.map(x => x.getBoundingClientRect().top); return t.every((v, i) => !i || v >= t[i - 1]); }),
      `${st}: order título → portada → descripción → en el inicio → BGG → internal (club → estado)`);
    ok(await J(() => { const z = document.querySelector('.zone-int'); return z.contains(document.querySelector('.club6')) && z.contains(document.querySelector('.est6')) && !z.contains(document.querySelector('.bgg6s')) && !z.contains(document.querySelector('.filas6')); }), `${st}: internal part holds only club + estado`);
  }
  ok(await J(() => { const z = document.querySelector('.zone-int'); return getComputedStyle(z).backgroundColor === 'rgba(0, 0, 0, 0)' && getComputedStyle(document.querySelector('.club6 .sbox')).backgroundColor === getComputedStyle(document.querySelector('.filas6 .sbox')).backgroundColor; }), 'D1: no band; internal boxes match public boxes');
  ok(await J(() => { const m = document.querySelector('#main').getBoundingClientRect(), row = document.querySelector('.zone-int .zdiv').getBoundingClientRect(), pad = parseFloat(getComputedStyle(document.querySelector('#main')).paddingLeft);
    return Math.abs(row.left - (m.left + pad)) <= 1 && Math.abs(row.right - (m.right - pad)) <= 1 && document.querySelectorAll('.zone-int .zl').length === 2; }), 'D1: two line halves span the content width');
  ok(await J(() => { const t = document.querySelector('.zone-int .zd-t').getBoundingClientRect(), z = document.querySelector('.zone-int .zdiv').getBoundingClientRect(); return Math.abs((t.left + t.right) / 2 - (z.left + z.right) / 2) <= 2 && /No se muestra en la web/.test(document.querySelector('.zone-int .zd-s').textContent); }), 'D1: label centered, note under it');
  ok(await J(() => { const u = document.querySelector('.useg'), o = u.querySelector('.on'); return getComputedStyle(u).backgroundColor !== getComputedStyle(u.closest('.sbox')).backgroundColor && getComputedStyle(o).backgroundColor !== getComputedStyle(u).backgroundColor; }), 'Unidades segmented track visible on its box');
  ok(await J(() => [...document.querySelectorAll('.sec-label')].map(l => getComputedStyle(l).font).every((f, i, a) => f === a[0])), 'section labels identical');

  /* R12 C2: Agregar a una fila closes the En el inicio box */
  await click('[data-status="published"]');
  ok(await J(() => { const b = document.querySelector('.filas6 .sbox .cta2-wrap:last-child .cta2'), r = b?.getBoundingClientRect();
    return !!b && r.height >= 40 && document.querySelectorAll('.filas6 .frow9 .pen').length === 1 && !/Sumar a otra fila/.test(document.querySelector('.filas6').textContent); }), 'C2: "+ Agregar a una fila" closes the box (≥40px); ✎ only on the manual row');
  await click('.filas6 .cta2'); ok(await J(() => /Filas del inicio/.test(document.querySelector('#sheet-act.open')?.textContent || '')), 'C2: opens Filas del inicio'); await click('#sheet-act [data-act="e-close"]');
  await scrollTo('.filas6', 60); await shot('filas-phone');

  /* R13: Datos de BGG — B3 label + the public page's fact layout, preview + Ver más / Ver menos */
  ok(await J(() => /^Datos de BGG\s*Solo lectura$/.test(document.querySelector('.bgg6s .sec-label').textContent.trim()) && !!document.querySelector('.bgg6s .sec-label .sec-note svg')), 'B3: label "Datos de BGG 🔒 Solo lectura" (read-only said once)');
  ok(await J(() => { const b = document.querySelector('.bgg6s .sbox'); const dts = [...b.querySelectorAll('dt')].map(d => d.textContent);
    return dts.join('|') === 'Año|Diseñadores' && /2018/.test(b.querySelector('.srowd dd').textContent) && b.querySelectorAll('.fcol .pk-pill-outline').length === 3 && !b.querySelector('.comm,.bgg-link,.bgg-foot'); }), 'closed: real data like the public page — Año 2018 + Diseñadores as 3 pills, nothing else');
  ok(await J(() => { const m = document.querySelector('.bgg-more'); return m.getAttribute('aria-expanded') === 'false' && /^Ver más$/.test(m.textContent.trim()) && m.getBoundingClientRect().height >= 44 && m === m.parentElement.lastElementChild; }), 'closed: "Ver más" disclosure at the bottom of the box (aria-expanded=false, 44px)');
  await scrollTo('.bgg6s', 60); await shot('bgg-closed');
  await click('.bgg-more');
  ok(await J(() => { const b = document.querySelector('.bgg6s .sbox'); return [...b.querySelectorAll('dt')].map(d => d.textContent).join('|') === 'Año|Diseñadores|Ilustradores|Mecánicas|Temáticas'
    && /Comunidad BGG/.test(b.textContent) && /Vienen de BoardGameGeek y se actualizan solos/.test(b.textContent) && !!b.querySelector('.bgg-link') && document.querySelector('.bgg-more').getAttribute('aria-expanded') === 'true' && /^Ver menos$/.test(document.querySelector('.bgg-more').textContent.trim()) && document.activeElement.classList.contains('bgg-more'); }),
    'open: every public fact + Comunidad BGG + sync note + link, "Ver menos", focus stays on the toggle');
  ok(!(await overflow()) && (await lines()) === 0, 'open: no overflow, no lines');
  await scrollTo('.bgg6s', 60); await shot('bgg-open');
  await click('.bgg-more'); ok(await J(() => document.querySelectorAll('.bgg6s dt').length === 2), 'Ver menos folds back to the preview');
  await click('[data-bgg="failed"]'); ok(await J(() => !document.querySelector('.bgg-more') && /Todavía no hay datos de BGG/.test(document.querySelector('.bgg6s').textContent)), 'failed: no toggle, a plain no-data note'); await click('[data-bgg="ok"]');

  /* R11 type + rhythm: the fonts the app ships, and one 8px-grid vertical rhythm */
  await click('[data-status="published"]'); await J(() => document.fonts.ready);
  ok(await J(() => ['400 14px Inter', '600 14px Inter', '30px "Bebas Neue"'].every(f => document.fonts.check(f)) && [...document.fonts].filter(f => f.status === 'loaded').map(f => f.family.replace(/"/g, '') + ' ' + f.weight).sort().join() === 'Bebas Neue 400,Inter 400,Inter 600'), 'real self-hosted Inter 400/600 + Bebas Neue load (no system fallback)');
  ok(await J(() => [...document.querySelectorAll('#device *')].every(el => ['400', '600'].includes(getComputedStyle(el).fontWeight))), 'every element declares 400 or 600 (the only Inter weights the app ships)');
  ok(await J(() => [...document.querySelectorAll('#main *')].filter(el => [...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim())).every(el => { const f = getComputedStyle(el).fontFamily; return /^Inter|^"Bebas Neue"/.test(f); })), 'page text uses Inter or Bebas Neue only');
  ok(await J(() => { const t = getComputedStyle(document.querySelector('#ed-name')); return t.fontSize === '30px' && t.lineHeight === '36px' && (t.letterSpacing === 'normal' || t.letterSpacing === '0px'); }), 'title matches public h1 (font-display text-3xl: 30/36, no tracking)');
  ok(await J(() => { const a = getComputedStyle(document.querySelector('.eback-row .back')).fontSize, b = getComputedStyle(document.querySelector('.eback-row .tbtn')).fontSize; return a === b; }), 'back row: ‹ Juegos and Ver en la ludoteca share one size');
  ok(await J(() => { const secs = [...document.querySelectorAll('#main .sec')]; const r = el => el.getBoundingClientRect();
    const labelBox = secs.every(s => Math.round(r(s.querySelector('.sec-label').nextElementSibling).top - r(s.querySelector('.sec-label')).bottom) === 8);
    const pub = ['.thead', '.img6', '.dfield6', '.filas6', '.bgg6s'].map(x => document.querySelector(x)); const pubGaps = pub.slice(1).every((s, i) => Math.round(r(s).top - r(pub[i]).bottom) === 24);
    const z = document.querySelector('.zone-int'), cap = z.querySelector('.zd-s'), club = z.querySelector('.club6'), est = z.querySelector('.est6');
    return labelBox && pubGaps && Math.round(r(z).top - r(pub[4]).bottom) === 40 && Math.round(r(club).top - r(cap).bottom) === 24 && Math.round(r(est).top - r(club).bottom) === 24; }),
    'rhythm: label→box 8px; title and every section 24px apart; divider 40px above, 24px to En el club');
  ok(await J(() => [...document.querySelectorAll('.filas6 .frow9 .gsub, .est6 .bl2')].every(el => el.getClientRects().length && el.getBoundingClientRect().height < 20)), 'row meta lines fit on one line at 375px');

  /* En el inicio (R9 F2) */
  await click('[data-status="published"]');
  ok(await J(() => [...document.querySelectorAll('.filas6 .frow9:not(.add) .gname')].map(x => x.textContent).join('|') === 'Destacados del club|Ingenio estratega|Recientemente añadidos'), 'En el inicio: one row per home row, in home order');
  ok(await J(() => { const r = [...document.querySelectorAll('.filas6 .frow9:not(.add)')]; return r[0].tagName === 'BUTTON' && r[1].tagName === 'DIV' && /cambia con el Nivel/.test(r[1].textContent); }), 'En el inicio (C2): manual rows editable (✎), automatic rows explain why');
  await click('[data-act="e-band-sheet"]'); await click('#sheet-act [data-v="e"]');
  ok(await J(() => /Nivel experto/.test(document.querySelector('.filas6').textContent) && !/Ingenio estratega/.test(document.querySelector('.filas6').textContent)), 'En el inicio: changing Nivel moves the level row');
  await click('.filas6 .cta2'); await click('#sheet-act [data-sec="2"]'); await click('#sheet-act [data-act="e-close"]');
  ok(await J(() => /Crea conexiones/.test(document.querySelector('.filas6').textContent)), 'En el inicio: Agregar a una fila → switch adds the row');
  await click('[data-status="retired"]'); ok(await J(() => /retirado/i.test(document.querySelector('.filas6 .fnote').textContent)), 'En el inicio: retired note');

  /* Unidades (R9 U2) */
  await click('[data-status="draft"]'); ok(await noCopias(), 'no "copia(s)" wording');
  ok(await J(() => document.querySelector('.useg .on').textContent === '1'), 'Unidades: 1 selected by default');
  await click('#u-set2'); ok((await units()) === 2 && await J(() => document.querySelector('#ebar .bl2').textContent === 'Cambios sin guardar'), 'Unidades: tap 2, dirty');
  await click('#u-set3'); ok((await units()) === 3 && await J(() => !!document.querySelector('.useg .ustep.on .stp-n')), 'Unidades: Más → 3 with an inline stepper');
  await scrollTo('.zone-int', 200); await shot('units-more');
  await click('#u-inc'); ok((await units()) === 4, 'Unidades: stepper + → 4'); await click('#u-dec'); await click('#u-dec');
  ok((await units()) === 2 && await J(() => !document.querySelector('.ustep') && document.querySelector('.useg .on').textContent === '2'), 'Unidades: − below 3 folds back to the 2 segment');

  /* V2 flows */
  await click('[data-status="draft"]'); await p.fill('#ed-name', 'Brass (ES)'); await wait(100);
  ok(await J(() => document.querySelector('#ebar .bl2').textContent === 'Cambios sin guardar'), 'dirty shows in Estado');
  await click('#ebar [data-act="e-publish"]'); await wait(900); ok(await J(() => E.status === 'published' && E.saved.name === 'Brass (ES)'), 'Publicar saves + publishes');
  await click('#snack .tbtn'); ok(await J(() => E.status === 'draft'), 'Deshacer');
  await click('[data-status="published"]'); await click('#ebar [data-act="e-retire-ask"]'); ok(await J(() => document.activeElement.dataset.act === 'e-close'), 'Retirar confirm, Cancelar focused');
  await click('#sheet-act [data-act="e-retire"]'); ok(await J(() => E.status === 'retired'), 'retired');
  await click('[data-act="e-band-sheet"]'); ok(await J(() => /sugiere/.test(document.querySelector('#sheet-act .sheet-text').textContent)), 'BGG suggestion in Nivel sheet'); await p.keyboard.press('Escape'); await wait(300);
  await click('[data-act="e-shelf-sheet"]'); await click('#sheet-act [data-v="3"]'); ok(await J(() => E.ed.shelf === 3), 'Estante pick');
  await click('[data-act="e-desc-edit"]'); await p.keyboard.type(' Fin.'); await click('.img6 .sec-label');
  ok(await J(() => document.querySelector('.desc-p').textContent.endsWith('Fin.')), 'description edit in place');
  await p.fill('#ed-name', ''); await click('#ebar [data-act="e-save"]'); ok(await J(() => !!E.errs.name && document.activeElement.id === 'ed-name'), 'name validation focuses field');
  await p.fill('#ed-name', 'Brass: Birmingham'); await click('#u-set1'); await click('[data-act="e-back"]'); ok(await J(() => !!document.querySelector('#sheet-act.open')), 'leave guard'); await click('#sheet-act [data-act="e-leave-discard"]'); await click('[data-act="e-open"]');
  await click('[data-act="e-bgg-toggle"]'); ok(await J(() => document.querySelectorAll('.fcol').length === 4), 'BGG expands');
  await click('[data-bgg="failed"]'); ok(!(await overflow()), 'failed no overflow'); await shot('failed'); await click('[data-act="e-retry"]'); await wait(1800);

  /* dark + desktop */
  await J(() => document.documentElement.dataset.theme = 'dark');
  await click('[data-status="published"]'); await scrollTo('.filas6', 60); await shot('dark-filas-bgg'); await click('.bgg-more'); await scrollTo('.bgg6s', 60); await shot('dark-bgg-open'); await click('.bgg-more');
  await J(() => delete document.documentElement.dataset.theme);
  await click('[data-vp="desk"]');
  await click('[data-status="published"]'); ok(!(await overflow()), 'desk no overflow'); await scrollTo('.filas6', 140); await shot('desk-closed');
  ok(await J(() => [...document.querySelectorAll('.bgg6s dt')].map(d => d.textContent).join('|') === 'Año|Diseñadores|Ilustradores'), 'desk closed: preview fills the first grid row (Diseñadores | Ilustradores)');
  await click('.bgg-more'); ok(!(await overflow()) && await J(() => getComputedStyle(document.querySelector('.bgg6s .fcols')).gridTemplateColumns.split(' ').length === 2), 'desk open: facts in the public 2-column grid'); await scrollTo('.bgg6s', 140); await shot('desk-open'); await click('.bgg-more');
  ok(await J(() => { const c = document.querySelector('.zone-int .club6').getBoundingClientRect(), e = document.querySelector('.zone-int .est6').getBoundingClientRect(); return e.left > c.right; }), 'desk: club | estado side by side');
  ok(errs.length === 0, 'no JS errors ' + errs.join(' | '));
  console.log(log.join('\n')); console.log(`\n${log.filter(l => l.startsWith('PASS')).length}/${log.length} passed · screenshots in ${OUT}`); await b.close();
  process.exitCode = log.some(l => l.startsWith('FAIL')) ? 1 : 0;
})().catch(e => { console.log(log.join('\n')); console.error('CRASH', e.message); process.exit(1); });
