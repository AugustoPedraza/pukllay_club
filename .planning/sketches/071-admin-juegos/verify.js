/* Headless-Chrome checks for sketch 071 (admin Juegos tab). Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/071-admin-juegos/verify.js
   Env: PLAYWRIGHT_CORE, SKETCH_URL, SHOTS_DIR (default <os tmp>/sketch-071-shots).
   Covers decisions 1-9 (notes/juegos-ui-redesign.md). */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();
const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/071-admin-juegos/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-071-shots'); fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);
const near = (a, b, t = 1.2) => Math.abs(a - b) <= t;

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const errs = [];
  const ctx = await browser.newContext({ viewport: { width: 375, height: 740 }, deviceScaleFactor: 2 });
  const p = await ctx.newPage();
  p.on('pageerror', e => errs.push('pageerror: ' + e.message));
  p.on('console', m => m.type() === 'error' && !/404|favicon/.test(m.text()) && errs.push('console: ' + m.text()));
  await p.goto(URL); await p.evaluate(() => document.fonts.ready);
  await p.evaluate(() => { document.getElementById('tools').style.display = 'none'; });
  const J = (f, a) => p.evaluate(f, a);
  const box = s => J(sel => { const e = document.querySelector(sel); if (!e) return null; const r = e.getBoundingClientRect(); return { t: r.top, b: r.bottom, l: r.left, r: r.right, w: r.width, h: r.height }; }, s);
  const textBox = s => J(sel => { const e = document.querySelector(sel); if (!e) return null; const g = document.createRange(); g.selectNodeContents(e); const r = g.getBoundingClientRect(); return { t: r.top, b: r.bottom, h: r.height }; }, s);
  const settle = async (pg = p) => {
    await pg.evaluate(() => [...document.querySelectorAll('img[loading="lazy"]')].forEach(i => i.loading = 'eager'));
    await pg.waitForFunction(() => [...document.querySelectorAll('img.cov')].every(i => i.complete), null, { timeout: 8000 }).catch(() => {});
    await pg.waitForTimeout(250);
  };
  await settle();

  /* ---------- decision 8: one list, three collapsible groups ---------- */
  const groups = await J(() => [...document.querySelectorAll('.lhead')].map(h => ({
    name: h.querySelector('.ln').textContent,
    count: +h.querySelector('.cnt').textContent,
    open: h.getAttribute('aria-expanded') === 'true',
    h: +h.getBoundingClientRect().height.toFixed(1)
  })));
  ok(groups.length === 3, `three groups (${groups.map(g => g.name).join(', ')})`);
  ok(groups.map(g => g.name).join('|') === 'Sin datos|Borradores|Juegos del club', `work groups sit on top (${groups.map(g => g.name).join(' > ')})`);
  const sum = groups.reduce((a, g) => a + g.count, 0);
  ok(sum === 435, `the groups PARTITION the catalog: ${groups.map(g => g.count).join(' + ')} = ${sum}`);
  ok(!groups[0].open && !groups[1].open && groups[2].open, `collapsed by default, catalog open (${groups.map(g => g.open).join(',')})`);
  ok(groups.every(g => g.h >= 44), `every group header is a 44px target (${groups.map(g => g.h).join(', ')})`);

  /* decision 10: a group header must not read as a row, and its caret is LEADING (a disclosure triangle),
     never a trailing "›", which under D-19i means "opens a page" */
  const caret = await J(() => {
    const c = document.querySelector('.lhead .caret'), h = c.closest('.lhead');
    const name = h.querySelector('.ln');
    return { leading: c.getBoundingClientRect().left < name.getBoundingClientRect().left,
      kids: c.querySelector('svg')?.children.length,
      caretLeft: +c.getBoundingClientRect().left.toFixed(1) };
  });
  ok(caret.leading, `the caret is LEADING, not in the row-chevron slot (caret at ${caret.caretLeft})`);
  ok(caret.kids > 0, 'the caret SVG is not empty (the bug 070 shipped when chevD was missing)');
  /* the four attributes that made a header read as a row — three must now differ */
  const sep = await J(() => {
    const h = document.querySelector('.lhead'), hn = h.querySelector('.ln');
    const r = document.querySelector('.row'), rn = r.querySelector('.name'), rc = r.querySelector('.chev');
    const bg = el => getComputedStyle(el).backgroundColor;
    return { headBg: bg(h), rowBg: bg(r),
      headTextLeft: +hn.getBoundingClientRect().left.toFixed(1), rowTextLeft: +rn.getBoundingClientRect().left.toFixed(1),
      headIconLeft: +h.querySelector('.caret').getBoundingClientRect().left.toFixed(1),
      rowIconLeft: +rc.getBoundingClientRect().left.toFixed(1),
      headBleed: +h.getBoundingClientRect().width.toFixed(1) };
  });
  ok(sep.headBg !== sep.rowBg, `header sits on a tonal band, the row does not (${sep.headBg} vs ${sep.rowBg})`);
  ok(Math.abs(sep.headIconLeft - sep.rowIconLeft) > 100, `the icons no longer share a slot (${sep.headIconLeft} vs ${sep.rowIconLeft})`);
  /* decision 13 — the page carries exactly TWO text left edges. Band text no longer outdents (that was the third
     edge, 44, aligning with nothing); it sits in the row-text column, and the caret holds the 16 edge instead. */
  const edges = await J(() => {
    const L = e => { const g = document.createRange(); g.selectNodeContents(e); return +g.getBoundingClientRect().left.toFixed(1); };
    const heads = [...document.querySelectorAll('.lhead')], row = document.querySelector('.row');
    const all = [L(document.querySelector('.ptitle')), ...heads.map(h => L(h.querySelector('.ln'))),
      +row.querySelector('.cov').getBoundingClientRect().left.toFixed(1), L(row.querySelector('.name'))];
    return { set: [...new Set(all)].sort((a, b) => a - b), carets: heads.map(h => +h.querySelector('.caret').getBoundingClientRect().left.toFixed(1)) };
  });
  ok(edges.set.length === 2 && near(edges.set[0], 16) && near(edges.set[1], 68), `exactly two text left edges (${edges.set.join(' / ')})`);
  ok(near(sep.headTextLeft, sep.rowTextLeft), `band text sits in the row-text column (${sep.headTextLeft} vs ${sep.rowTextLeft})`);
  ok(edges.carets.every(c => near(c, 16)), `every caret holds the 16 edge, none ragged (${edges.carets.join(', ')})`);
  ok(near(sep.headBleed, 375, 1), `the band is full-bleed (${sep.headBleed})`);
  const rot = await J(() => ({
    collapsed: getComputedStyle(document.querySelector('.lhead[aria-expanded="false"] .caret')).transform,
    expanded: getComputedStyle(document.querySelector('.lhead[aria-expanded="true"] .caret')).transform
  }));
  ok(rot.collapsed !== rot.expanded, `the caret rotates to show state (${rot.collapsed} vs ${rot.expanded})`);

  /* no Pendientes page and no badge survive decision 8 */
  ok(await J(() => !document.querySelector('.badge') && !document.querySelector('[data-act="pend"]')), 'the Pendientes page and its badge are gone (decision 8 replaces D-19g here)');
  ok(await J(() => document.querySelectorAll('.hacts .ibtn').length === 1 && document.querySelector('.hacts .ibtn').dataset.act === 'add'), 'the header keeps only "+"');

  /* ---------- rhythm at rest ---------- */
  const phead = await box('.phead'), field = await box('.sfield input');
  const lh0 = await textBox('.lhead .ln');
  ok(near(field.h, 48), `main control is a 48px field (${field.h.toFixed(1)})`);
  ok(near(field.t - phead.b, 16, 1.5), `title row -> field 16, as 069 raised (${(field.t - phead.b).toFixed(1)})`);
  /* decision 11 measures to the BAND EDGE, not the heading text: decision 10 made the box visible, so the box
     is now what the eye reads. Target 24 to the band, 0 between the joined work bands, 32 to the catalog. */
  const bands = await J(() => {
    const hs = [...document.querySelectorAll('.lhead')].map(h => h.getBoundingClientRect());
    const f = document.querySelector('.sfield input').getBoundingClientRect();
    const r0 = document.querySelector('.lgroup.main .row').getBoundingClientRect();
    return { toFirst: +(hs[0].top - f.bottom).toFixed(1), seam: +(hs[1].top - hs[0].bottom).toFixed(1),
             toMain: +(hs[2].top - hs[1].bottom).toFixed(1), toRow: +(r0.top - hs[2].bottom).toFixed(1) };
  });
  ok(near(bands.toFirst, 24, 1.5), `field -> work block 24 (${bands.toFirst})`);
  ok(bands.seam === 0, `the two work bands are contiguous — no stripe (${bands.seam})`);
  ok(near(bands.toMain, 32, 1.5), `work block -> catalog 32 (${bands.toMain})`);
  ok(bands.toRow === 0, `the catalog band is welded to its rows (${bands.toRow})`);
  ok(new Set([bands.toFirst, bands.seam, bands.toMain]).size === 3, `no repeating pitch: ${bands.toFirst} / ${bands.seam} / ${bands.toMain}`);
  const ranks = await J(() => { const g = s => { const e = document.querySelector(s); const c = getComputedStyle(e); return parseFloat(c.fontSize) + '/' + c.fontWeight; };
    return { title: g('.ptitle'), lhead: g('.lhead'), name: g('.row .name'), field: g('.sfield input') }; });
  ok(ranks.title === '22/600' && ranks.lhead === '15/600' && ranks.name === '15/400' && ranks.field === '16/400',
    `type ranks hold (title ${ranks.title}, heading ${ranks.lhead}, row ${ranks.name}, field ${ranks.field})`);
  ok(await J(() => [...document.querySelectorAll('svg')].every(s => s.children.length > 0)), 'no empty SVG icons anywhere');
  const oflow = await J(() => { const s = document.querySelector('.scroller'); return s.scrollWidth - s.clientWidth; });
  ok(oflow <= 0, `no horizontal overflow (${oflow}px)`);
  await p.screenshot({ path: path.join(OUT, '01-juegos-rest-375x740-light.png') });

  /* the catalog's rows: no row repeats what its group heading already says */
  const rowsInfo = await J(() => {
    const rows = [...document.querySelectorAll('.row')];
    return { n: rows.length, h: +rows[0].getBoundingClientRect().height.toFixed(1),
      anySinDatos: rows.some(r => /Sin datos/.test(r.textContent)),
      anyBorrador: rows.some(r => /Borrador/.test(r.textContent)),
      chev: !!rows[0].querySelector('.chev svg path') };
  });
  ok(rowsInfo.n === 50, `the catalog group pages 50 at a time (${rowsInfo.n})`);
  ok(near(rowsInfo.h, 64, 1.5), `game row 64px (${rowsInfo.h})`);
  ok(!rowsInfo.anySinDatos && !rowsInfo.anyBorrador, 'a row never repeats its group\'s state ("Sin datos" x49 under a heading saying it was noise)');
  ok(rowsInfo.chev, 'a game row keeps its chevron — it opens the editor (D-19i)');

  /* ---------- opening a group ---------- */
  const before = await J(() => document.querySelector('[data-g="gap"]').getBoundingClientRect().top);
  await p.click('[data-g="gap"]'); await p.waitForTimeout(350); await settle();
  const opened = await J(() => ({
    expanded: document.querySelector('[data-g="gap"]').getAttribute('aria-expanded'),
    rows: document.querySelector('[data-g="gap"]').closest('.lgroup').querySelectorAll('.row').length,
    headTop: +document.querySelector('[data-g="gap"]').getBoundingClientRect().top.toFixed(1),
    hint: document.querySelector('[data-g="gap"]').closest('.lgroup').querySelector('.hint')?.textContent.trim()
  }));
  ok(opened.expanded === 'true' && opened.rows === 49, `opening "Sin datos" shows its 49 rows (${opened.rows})`);
  ok(near(opened.headTop, before, 2), `the tapped heading stays put — opening a group never scrolls the page (${before.toFixed(1)} -> ${opened.headTop})`);
  ok(/sin tapa/.test(opened.hint || ''), `the group carries one hint line ("${opened.hint}")`);
  /* decision 13 holds in the OPEN state too — the hint line only exists here, and it must land on one of the two
     edges (16), not introduce a third. Sampled at rest this was invisible. */
  const openEdges = await J(() => {
    const L = e => { const g = document.createRange(); g.selectNodeContents(e); return +g.getBoundingClientRect().left.toFixed(1); };
    const grp = document.querySelector('[data-g="gap"]').closest('.lgroup');
    return [...new Set([L(document.querySelector('.ptitle')), L(grp.querySelector('.lhead .ln')),
      L(grp.querySelector('.hint')), L(grp.querySelector('.row .name')),
      +grp.querySelector('.row .cov').getBoundingClientRect().left.toFixed(1)])].sort((a, b) => a - b);
  });
  ok(openEdges.length === 2 && near(openEdges[0], 16) && near(openEdges[1], 68), `still two edges with a group open — the hint lands on 16 (${openEdges.join(' / ')})`);
  await p.screenshot({ path: path.join(OUT, '02-group-open-375x740-light.png') });
  await p.click('[data-g="gap"]'); await p.waitForTimeout(300);

  /* ---------- decision 9: the search hides going down, returns going up ---------- */
  const sc = s => p.evaluate(y => { document.querySelector('.scroller').scrollTop = y; }, s);
  await sc(0); await p.waitForTimeout(200);
  ok(await J(() => !document.getElementById('device').classList.contains('hidesearch')), 'at the top the search is in place');
  for (const y of [200, 420, 700, 1000]) { await sc(y); await p.waitForTimeout(120); }
  await p.waitForTimeout(250);
  const down = await J(() => ({
    hidden: document.getElementById('device').classList.contains('hidesearch'),
    searchTop: +document.querySelector('.search').getBoundingClientRect().top.toFixed(1),
    bar: getComputedStyle(document.getElementById('device')).getPropertyValue('--bar').trim(),
    headTop: +document.querySelector('.lhead').getBoundingClientRect().top.toFixed(1)
  }));
  ok(down.hidden, 'scrolling down hides the search');
  ok(down.searchTop < 53, `the search is off the top of the scroller (${down.searchTop} < 53)`);
  ok(down.bar === '0px', `the group heading pins to the very top while the search is away (--bar ${down.bar})`);
  await settle(); await p.screenshot({ path: path.join(OUT, '03-search-hidden-375x740-light.png') });
  for (const y of [900, 780, 640]) { await sc(y); await p.waitForTimeout(120); }
  await p.waitForTimeout(250);
  ok(await J(() => !document.getElementById('device').classList.contains('hidesearch')), 'the smallest flick upward brings the search back');
  await settle(); await p.screenshot({ path: path.join(OUT, '04-search-back-375x740-light.png') });

  /* it must never hide while the field has focus — its dropdown is open there */
  await sc(0); await p.waitForTimeout(200);
  await p.click('#q'); await p.waitForTimeout(200);
  await p.fill('#q', 'cat'); await p.waitForTimeout(200);
  const kbd = await box('.kbd-sim'), sugg = await box('.sugg');
  ok(kbd.h === 292 && sugg.b <= kbd.t + 0.5, `suggestions end above the 292px keyboard (${sugg.b.toFixed(1)} vs ${kbd.t})`);
  const sTypes = await J(() => [...document.querySelectorAll('.sugg .srow')].map(r => r.dataset.act));
  ok(sTypes.includes('open') && sTypes[sTypes.length - 1] === 'create', `name search: matches then "Crear «texto»" (${sTypes.join(',')})`);
  await p.screenshot({ path: path.join(OUT, '05-search-typing-375x740-light.png') });
  await p.fill('#q', '342942'); await p.waitForTimeout(200);
  ok(await J(() => document.querySelector('.sugg .srow')?.dataset.act === 'addbgg'), 'a pasted BGG number offers to add it');
  await p.fill('#q', 'https://boardgamegeek.com/boardgame/342942/ark-nova'); await p.waitForTimeout(200);
  ok(await J(() => document.querySelector('.sugg .srow')?.dataset.act === 'addbgg'), 'a pasted BGG link offers to add it');
  await p.fill('#q', ''); await p.evaluate(() => document.activeElement.blur()); await p.waitForTimeout(300);

  /* ---------- the "+" sheet ---------- */
  await p.click('[data-act="add"]'); await p.waitForTimeout(400);
  const goBtn = await box('[data-act="addgo"]'), kbd2 = await box('.kbd-sim'), sx = await box('.sh-x');
  ok(goBtn.b <= kbd2.t, `Agregar sits above the keyboard (${goBtn.b.toFixed(1)} vs ${kbd2.t})`);
  ok(sx.w >= 44 && sx.h >= 44, `sheet closes with a 44px X, D-19e (${sx.w}x${sx.h})`);
  ok(!(await J(() => /Cancelar/.test(document.querySelector('.sheet').textContent))), 'no Cancelar row in the sheet (D-19e)');
  await p.screenshot({ path: path.join(OUT, '06-add-sheet-375x740-light.png') });
  await p.fill('#bg', 'hola'); await p.click('[data-act="addgo"]'); await p.waitForTimeout(200);
  ok(await J(() => { const e = document.querySelector('#bgerr'); return e && !e.hidden && /Pegá un número de BGG/.test(e.textContent); }), 'invalid input shows the shipped error copy');
  await p.fill('#bg', '13'); await p.click('[data-act="addgo"]'); await p.waitForTimeout(250);
  ok(await J(() => !!document.querySelector('.edp')), 'a known BGG id shows the edition prompt (D-03)');
  await p.screenshot({ path: path.join(OUT, '07-edition-prompt-375x740-light.png') });
  await p.click('[data-act="edcancel"]'); await p.waitForTimeout(150);
  await p.fill('#bg', '342942'); await p.click('[data-act="addgo"]'); await p.waitForTimeout(300);
  ok(await J(() => /borrador/i.test(document.querySelector('#snack').textContent)), 'adding shows "Juego agregado como borrador"');
  await p.waitForTimeout(1800);
  const afterAdd = await J(() => [...document.querySelectorAll('.lhead')].map(h => h.querySelector('.ln').textContent + ' ' + h.querySelector('.cnt').textContent));
  ok(/Borradores 2/.test(afterAdd.join('|')), `the new draft lands in Borradores, whose count moves live (${afterAdd.join(' | ')})`);
  await p.screenshot({ path: path.join(OUT, '08-added-375x740-light.png') });

  /* ---------- the editor, and the page bar that serves it ---------- */
  await p.click('.row'); await p.waitForTimeout(300); await settle();
  ok(await J(() => document.querySelector('main .back')?.textContent.trim() === 'Juegos'), 'a row opens the editor, which goes back to Juegos');
  await p.evaluate(() => document.querySelector('.scroller').scrollTop = 400); await p.waitForTimeout(300);
  const ebar = await J(() => {
    const bar = document.getElementById('pbar');
    return { shown: getComputedStyle(bar).opacity === '1', h: +bar.getBoundingClientRect().height.toFixed(1),
      title: bar.querySelector('.pbt')?.textContent, back: bar.querySelector('.back')?.textContent.trim(),
      focusableBacks: [...document.querySelectorAll('.back')].filter(b => !b.inert && !b.closest('[inert]')).length };
  });
  ok(ebar.shown && near(ebar.h, 44), `the editor keeps the 44px page bar (${ebar.h})`);
  ok(/Juegos/.test(ebar.back || ''), `the bar carries back + the game's name ("${ebar.back}" / "${ebar.title}")`);
  ok(ebar.focusableBacks === 1, `exactly one focusable back control (${ebar.focusableBacks})`);
  await p.click('#pbar .back'); await p.waitForTimeout(300);
  ok(await J(() => document.querySelector('.ptitle').textContent === 'Juegos' && document.querySelector('.scroller').scrollTop === 0), 'the bar\'s back returns to Juegos at the top');

  /* ---------- contrast, both themes ---------- */
  const contrast = () => J(() => {
    const parse = s => { if (!s || s === 'transparent') return null;
      if (/^color\(srgb/.test(s)) { const m = s.match(/[\d.]+/g).map(Number); return { r: m[0] * 255, g: m[1] * 255, b: m[2] * 255, a: /\//.test(s) ? m[3] : 1 }; }
      const m = s.match(/[\d.]+/g); if (!m) return null; return { r: +m[0], g: +m[1], b: +m[2], a: m[3] === undefined ? 1 : +m[3] }; };
    const lum = c => { const f = v => { v /= 255; return v <= .03928 ? v / 12.92 : Math.pow((v + .055) / 1.055, 2.4); }; return .2126 * f(c.r) + .7152 * f(c.g) + .0722 * f(c.b); };
    const over = (f, b) => ({ r: f.r * f.a + b.r * (1 - f.a), g: f.g * f.a + b.g * (1 - f.a), b: f.b * f.a + b.b * (1 - f.a), a: 1 });
    const bgOf = el => { let n = el; while (n && n !== document.documentElement) { const c = parse(getComputedStyle(n).backgroundColor); if (c && c.a === 1) return c; n = n.parentElement; } return { r: 255, g: 255, b: 255, a: 1 }; };
    const ratio = el => { const b = bgOf(el); const f = over(parse(getComputedStyle(el).color), b); const [L1, L2] = [lum(f), lum(b)].sort((x, y) => y - x); return +((L1 + .05) / (L2 + .05)).toFixed(2); };
    return { name: ratio(document.querySelector('.row .name')), head: ratio(document.querySelector('.lhead')),
      cnt: ratio(document.querySelector('.lhead .cnt')), sub: ratio(document.querySelector('.row .sub')) };
  });
  const cl = await contrast();
  ok(cl.name >= 4.5 && cl.head >= 4.5 && cl.cnt >= 4.5 && cl.sub >= 4.5, `light: name ${cl.name}, heading ${cl.head}, count ${cl.cnt}, year ${cl.sub} (all >= 4.5)`);
  await p.evaluate(() => document.documentElement.dataset.theme = 'dark'); await p.waitForTimeout(250); await settle();
  const cd = await contrast();
  ok(cd.name >= 4.5 && cd.head >= 4.5 && cd.cnt >= 4.5 && cd.sub >= 4.5, `dark: name ${cd.name}, heading ${cd.head}, count ${cd.cnt}, year ${cd.sub} (all >= 4.5)`);
  await p.screenshot({ path: path.join(OUT, '09-juegos-rest-375x740-dark.png') });
  await ctx.close();

  /* ---------- viewports: what the collapsed groups buy, and what hiding the search buys ---------- */
  for (const [w, h] of [[360, 640], [375, 667], [390, 844]]) {
    const c2 = await browser.newContext({ viewport: { width: w, height: h }, deviceScaleFactor: 2 });
    const q = await c2.newPage();
    q.on('pageerror', e => errs.push(`pageerror ${w}x${h}: ` + e.message));
    await q.goto(URL); await q.evaluate(() => document.fonts.ready);
    await q.evaluate(() => { document.getElementById('tools').style.display = 'none'; });
    await q.evaluate(() => [...document.querySelectorAll('img[loading="lazy"]')].forEach(i => i.loading = 'eager'));
    await q.waitForTimeout(1600);
    const m = await q.evaluate(() => {
      const scr = document.querySelector('.scroller'), tabs = document.querySelector('.tabs').getBoundingClientRect().top;
      const rows = [...document.querySelectorAll('.row')];
      const top = scr.getBoundingClientRect().top;
      return { rest: rows.filter(r => { const b = r.getBoundingClientRect(); return b.top >= top - 1 && b.bottom <= tabs; }).length,
               oflow: scr.scrollWidth - scr.clientWidth };
    });
    await q.evaluate(() => { document.querySelector('.scroller').scrollTop = 1000; });
    await q.waitForTimeout(400);
    const hid = await q.evaluate(() => {
      const tabs = document.querySelector('.tabs').getBoundingClientRect().top;
      const scr = document.querySelector('.scroller').getBoundingClientRect().top;
      return { hidden: document.getElementById('device').classList.contains('hidesearch'),
        rows: [...document.querySelectorAll('.row')].filter(r => { const b = r.getBoundingClientRect(); return b.top >= scr - 1 && b.bottom <= tabs; }).length };
    });
    ok(m.oflow <= 0, `${w}x${h}: no horizontal overflow (${m.oflow}px)`);
    ok(hid.hidden && hid.rows >= m.rest, `${w}x${h}: ${m.rest} rows at rest -> ${hid.rows} with the search hidden`);
    await q.screenshot({ path: path.join(OUT, `10-juegos-${w}x${h}-light.png`) });
    await c2.close();
  }

  await browser.close();
  ok(errs.length === 0, `no page errors (${errs.length ? errs.join(' | ') : 'none'})`);
  console.log(log.join('\n'));
  console.log(`\n${log.filter(l => l.startsWith('PASS')).length}/${log.length} passed · shots in ${OUT}`);
  process.exit(log.some(l => l.startsWith('FAIL')) ? 1 : 0);
})();
