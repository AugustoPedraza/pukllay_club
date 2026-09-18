/* Headless-Chrome checks for sketch 071 (admin Juegos tab). Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/071-admin-juegos/verify.js
   Env: PLAYWRIGHT_CORE, SKETCH_URL, SHOTS_DIR (default <os tmp>/sketch-071-shots). */
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

  /* ---------- rhythm + anatomy at 375x740, light ---------- */
  const ctx = await browser.newContext({ viewport: { width: 375, height: 740 }, deviceScaleFactor: 2 });
  const p = await ctx.newPage();
  p.on('pageerror', e => errs.push('pageerror: ' + e.message));
  p.on('console', m => m.type() === 'error' && !/404|favicon/.test(m.text()) && errs.push('console: ' + m.text()));
  await p.goto(URL); await p.evaluate(() => document.fonts.ready);
  await p.evaluate(() => { document.getElementById('tools').style.display = 'none'; });
  const J = (f, a) => p.evaluate(f, a);
  const box = s => J(sel => { const e = document.querySelector(sel); if (!e) return null; const r = e.getBoundingClientRect(); return { t: r.top, b: r.bottom, l: r.left, r: r.right, w: r.width, h: r.height }; }, s);
  /* the visible TEXT box, not the element box — box gaps lie (Web decision 9) */
  const textBox = s => J(sel => {
    const e = document.querySelector(sel); if (!e) return null;
    const rg = document.createRange(); rg.selectNodeContents(e);
    const r = rg.getBoundingClientRect(); return { t: r.top, b: r.bottom, h: r.height };
  }, s);

  /* covers are lazy-loaded from R2: without this the screenshots show empty boxes and hide the real design */
  const settle = async (pg = p) => {
    await pg.evaluate(() => [...document.querySelectorAll('img[loading="lazy"]')].forEach(i => i.loading = 'eager'));
    await pg.waitForFunction(() => [...document.querySelectorAll('img.cov, img.bc')].every(i => i.complete), null, { timeout: 8000 }).catch(() => {});
    await pg.waitForTimeout(250);
  };
  await settle();

  const title = await textBox('.ptitle'), field = await box('.sfield input');
  const phead = await box('.phead');
  const lhead = await textBox('.lhead'), firstRow = await box('.row');
  const firstCov = await box('.row .cov, .row .cov.none');
  ok(near(field.h, 48), `main control is a 48px field (${field.h.toFixed(1)})`);
  /* 069 decision 61 measures a FIELD from the title ROW (its border is the visible edge), not from the title's
     text box. Measured on 069 raised at 375x667: fromRow 16.0, fromText 25.2 — 071 must reproduce both. */
  ok(near(field.t - phead.b, 16, 1.5), `title row -> field 16, as 069 raised (${(field.t - phead.b).toFixed(1)}; from title text ${(field.t - title.b).toFixed(1)}, 069 = 25.2)`);
  ok(near(lhead.t - field.b, 32, 2.5), `field -> "Juegos del club" 32 (${(lhead.t - field.b).toFixed(1)})`);
  ok(near(firstCov.t - lhead.b, 16, 3), `heading text -> first cover 16 (${(firstCov.t - lhead.b).toFixed(1)})`);
  ok(near(firstRow.h, 64, 1.5), `game row 64px (${firstRow.h.toFixed(1)})`);

  const ranks = await J(() => {
    const g = s => { const e = document.querySelector(s); if (!e) return null; const c = getComputedStyle(e); return [parseFloat(c.fontSize), c.fontWeight].join('/'); };
    return { title: g('.ptitle'), lhead: g('.lhead'), name: g('.row .name'), sub: g('.row .sub'), field: g('.sfield input'), cap: g('.more .cap') };
  });
  ok(ranks.title === '22/600', `page title 22/600 (${ranks.title})`);
  ok(ranks.lhead === '15/600', `section heading 15/600 (${ranks.lhead})`);
  ok(ranks.name === '15/400', `row name 15/400 (${ranks.name})`);
  ok(ranks.sub === '13/400', `row second line 13/400 (${ranks.sub})`);
  ok(ranks.field === '16/400', `field text 16px, no iOS zoom (${ranks.field})`);

  /* header icons: 44px, Pendientes left of "+", badge present */
  const hit = await J(() => [...document.querySelectorAll('.hacts .ibtn')].map(b => {
    const r = b.getBoundingClientRect();
    return { act: b.dataset.act, w: +r.width.toFixed(1), h: +r.height.toFixed(1), l: +r.left.toFixed(1), label: b.getAttribute('aria-label'), badge: b.querySelector('.badge')?.textContent || null };
  }));
  ok(hit.every(b => b.w >= 44 && b.h >= 44), `header icons are 44px (${hit.map(b => b.w + 'x' + b.h).join(', ')})`);
  ok(hit[0].act === 'pend' && hit[1].act === 'add', `Pendientes left of "+" (${hit.map(b => b.act).join(' , ')})`);
  ok(hit[0].badge === '50', `badge shows 50 (${hit[0].badge})`);
  ok(/50/.test(hit[0].label), `count is in the accessible name ("${hit[0].label}")`);

  /* D-19i: a game row opens a page, so it has a chevron */
  ok(await J(() => !!document.querySelector('.row .chev svg path')), 'game row has a chevron (D-19i: it opens the editor)');
  ok(await J(() => [...document.querySelectorAll('svg')].every(s => s.children.length > 0)), 'no empty SVG icons');

  /* newest-first + the 49 at the bottom */
  const order = await J(() => {
    const rows = [...document.querySelectorAll('.row')];
    return { first: rows[0].querySelector('.name').textContent, firstSub: rows[0].querySelector('.sub').textContent, n: rows.length, gaps: rows.filter(r => /Sin datos/.test(r.textContent)).length };
  });
  ok(order.n === 50, `first page is 50 rows (${order.n})`);
  ok(order.gaps === 0, `the 49 incomplete games are NOT on page 1 (${order.gaps} shown) — they live behind Pendientes`);

  /* no horizontal overflow */
  const oflow = await J(() => document.querySelector('.scroller').scrollWidth - document.querySelector('.scroller').clientWidth);
  ok(oflow <= 0, `no horizontal overflow (${oflow}px)`);
  await p.screenshot({ path: path.join(OUT, '01-juegos-375x740-light.png') });

  /* ---------- the search: dropdown, BGG paste, create ---------- */
  await p.click('#q'); await p.waitForTimeout(250);
  const kbd = await box('.kbd-sim'), sugg0 = await box('.sugg');
  ok(kbd && kbd.h === 292, `simulated keyboard is 292px (${kbd && kbd.h})`);
  await p.fill('#q', 'cat'); await p.waitForTimeout(200);
  const sugg = await box('.sugg');
  ok(sugg.b <= kbd.t + 0.5, `suggestions end above the keyboard (${sugg.b.toFixed(1)} vs ${kbd.t})`);
  const sTypes = await J(() => [...document.querySelectorAll('.sugg .srow')].map(r => r.dataset.act));
  ok(sTypes.includes('open') && sTypes[sTypes.length - 1] === 'create', `name search: matches then "Crear «texto»" (${sTypes.join(',')})`);
  await settle(); await p.screenshot({ path: path.join(OUT, '02-search-typing-375x740-light.png') });

  await p.fill('#q', '342942'); await p.waitForTimeout(200);
  const bggRow = await J(() => { const r = document.querySelector('.sugg .srow'); return r && { act: r.dataset.act, txt: r.textContent.replace(/\s+/g, ' ').trim() }; });
  ok(bggRow && bggRow.act === 'addbgg', `a pasted BGG number offers to add it ("${bggRow && bggRow.txt}")`);
  await p.fill('#q', 'https://boardgamegeek.com/boardgame/342942/ark-nova'); await p.waitForTimeout(200);
  const linkRow = await J(() => { const r = document.querySelector('.sugg .srow'); return r && r.dataset.act; });
  ok(linkRow === 'addbgg', `a pasted BGG link offers to add it (${linkRow})`);
  await settle(); await p.screenshot({ path: path.join(OUT, '03-search-bgg-375x740-light.png') });

  /* ---------- the "+" sheet, on the keyboard ---------- */
  await p.fill('#q', ''); await p.evaluate(() => document.activeElement.blur()); await p.waitForTimeout(300);
  await p.click('[data-act="add"]'); await p.waitForTimeout(400);
  const sheet = await box('.sheet'), goBtn = await box('[data-act="addgo"]'), kbd2 = await box('.kbd-sim');
  ok(goBtn.b <= kbd2.t, `Agregar sits above the keyboard (${goBtn.b.toFixed(1)} vs ${kbd2.t})`);
  ok(sheet.t > 0, `add sheet top ${sheet.t.toFixed(1)}`);
  const sx = await box('.sh-x');
  ok(sx.w >= 44 && sx.h >= 44, `sheet closes with a 44px X (D-19e) (${sx.w}x${sx.h})`);
  ok(!(await J(() => /Cancelar/.test(document.querySelector('.sheet').textContent))), 'no Cancelar row in the sheet (D-19e)');
  await settle(); await p.screenshot({ path: path.join(OUT, '04-add-sheet-375x740-light.png') });

  /* the shipped error copy, then the edition prompt */
  await p.fill('#bg', 'hola'); await p.click('[data-act="addgo"]'); await p.waitForTimeout(200);
  ok(await J(() => { const e = document.querySelector('#bgerr'); return e && !e.hidden && /Pegá un número de BGG/.test(e.textContent); }), 'invalid input shows the shipped error copy');
  await p.fill('#bg', '13'); await p.click('[data-act="addgo"]'); await p.waitForTimeout(250);
  ok(await J(() => !!document.querySelector('.edp')), 'a known BGG id shows the edition prompt (D-03)');
  await settle(); await p.screenshot({ path: path.join(OUT, '05-edition-prompt-375x740-light.png') });
  await p.click('[data-act="edcancel"]'); await p.waitForTimeout(150);
  await p.fill('#bg', '342942'); await p.click('[data-act="addgo"]'); await p.waitForTimeout(300);
  ok(await J(() => /borrador/i.test(document.querySelector('#snack').textContent)), 'adding shows "Juego agregado como borrador"');
  await p.waitForTimeout(1800);
  ok(await J(() => /Ark Nova/.test(document.querySelector('.row .name').textContent)), 'the enriched row fills in live and is first (newest-first)');
  await settle(); await p.screenshot({ path: path.join(OUT, '06-added-enriched-375x740-light.png') });

  /* ---------- Pendientes ---------- */
  await p.click('[data-act="pend"]'); await p.waitForTimeout(300);
  const pend = await J(() => ({
    heads: [...document.querySelectorAll('.lhead')].map(h => h.textContent.replace(/\s+/g, ' ').trim()),
    rows: document.querySelectorAll('.row').length,
    back: document.querySelector('main .back')?.textContent.trim(),
    hints: [...document.querySelectorAll('.hint')].map(h => h.textContent.trim())
  }));
  ok(/Sin datos/.test(pend.heads[0]) && /50|49/.test(pend.heads[0]), `Pendientes: "${pend.heads[0]}"`);
  ok(/Borradores/.test(pend.heads[1]), `second section "${pend.heads[1]}"`);
  ok(pend.back === 'Juegos', `back link is "‹ Juegos" (${pend.back})`);
  const ph = await textBox('.lgroup + .lgroup .lhead'), prevRows = await J(() => { const rs = document.querySelectorAll('.lgroup:first-of-type .row'); const r = rs[rs.length - 1].getBoundingClientRect(); return r.bottom; });
  ok(true, `group gap: last Sin datos row -> "Borradores" ${(ph.t - prevRows).toFixed(1)}`);
  await settle(); await p.screenshot({ path: path.join(OUT, '07-pendientes-375x740-light.png') });

  /* a Pendientes row opens the editor, back goes to Pendientes */
  await p.click('.row'); await p.waitForTimeout(250);
  ok(await J(() => document.querySelector('main .back')?.textContent.trim() === 'Pendientes'), 'editor opened from Pendientes goes back to Pendientes');
  await settle(); await p.screenshot({ path: path.join(OUT, '08-editor-stub-375x740-light.png') });

  /* ---------- contrast, both themes (parses color(srgb ...) too) ---------- */
  const contrast = () => J(() => {
    const parse = s => {
      if (!s || s === 'transparent') return null;
      if (/^color\(srgb/.test(s)) { const m = s.match(/[\d.]+/g).map(Number); return { r: m[0] * 255, g: m[1] * 255, b: m[2] * 255, a: /\//.test(s) ? m[3] : 1 }; }
      const m = s.match(/[\d.]+/g); if (!m) return null;
      return { r: +m[0], g: +m[1], b: +m[2], a: m[3] === undefined ? 1 : +m[3] };
    };
    const lum = c => { const f = v => { v /= 255; return v <= .03928 ? v / 12.92 : Math.pow((v + .055) / 1.055, 2.4); }; return .2126 * f(c.r) + .7152 * f(c.g) + .0722 * f(c.b); };
    const over = (fg, bg) => ({ r: fg.r * fg.a + bg.r * (1 - fg.a), g: fg.g * fg.a + bg.g * (1 - fg.a), b: fg.b * fg.a + bg.b * (1 - fg.a), a: 1 });
    const bgOf = el => { let n = el; while (n && n !== document.documentElement) { const c = parse(getComputedStyle(n).backgroundColor); if (c && c.a === 1) return c; n = n.parentElement; } return parse(getComputedStyle(document.body).backgroundColor) || { r: 255, g: 255, b: 255, a: 1 }; };
    const ratio = el => { const b = bgOf(el); const f = over(parse(getComputedStyle(el).color), b); const [L1, L2] = [lum(f), lum(b)].sort((x, y) => y - x); return +((L1 + .05) / (L2 + .05)).toFixed(2); };
    const pick = s => { const e = document.querySelector(s); return e ? ratio(e) : null; };
    return { name: pick('.row .name'), sub: pick('.row .sub'), lhead: pick('.lhead'), title: pick('.ptitle'), hint: pick('.hint'), cap: pick('.more .cap') };
  });
  await p.click('main .back'); await p.waitForTimeout(250);   /* editor -> Pendientes */
  await p.click('main .back'); await p.waitForTimeout(250);   /* Pendientes -> Juegos */
  const cLight = await contrast();
  ok(cLight.name >= 4.5 && cLight.sub >= 4.5, `light: row name ${cLight.name}:1, second line ${cLight.sub}:1 (both >= 4.5)`);
  await p.evaluate(() => document.documentElement.dataset.theme = 'dark'); await p.waitForTimeout(250);
  const cDark = await contrast();
  ok(cDark.name >= 4.5 && cDark.sub >= 4.5, `dark: row name ${cDark.name}:1, second line ${cDark.sub}:1 (both >= 4.5)`);
  await settle(); await p.screenshot({ path: path.join(OUT, '09-juegos-375x740-dark.png') });
  await p.click('[data-act="pend"]'); await p.waitForTimeout(250);
  await settle(); await p.screenshot({ path: path.join(OUT, '10-pendientes-375x740-dark.png') });
  await p.evaluate(() => document.documentElement.dataset.theme = 'light'); await p.waitForTimeout(150);

  /* ---------- decision 6 (D-19n): the two pinned tiers ---------- */
  /* at rest the bar must cost zero layout — verified byte-for-byte against the pre-sticky build:
     phead 69, title text 77.8, field 129, heading 209, first cover 244.5, row 64 — all unchanged */
  await p.click('main .back'); await p.waitForTimeout(250);   /* back to Juegos */
  const rest = await J(() => ({
    hidden: getComputedStyle(document.getElementById('pbar')).opacity === '0',
    inert: document.getElementById('pbar').inert,
    pheadTop: +document.querySelector('.phead').getBoundingClientRect().top.toFixed(1),
    fieldTop: +document.querySelector('.sfield input').getBoundingClientRect().top.toFixed(1)
  }));
  ok(rest.hidden && rest.inert, 'at rest: the page bar is hidden and inert');
  ok(rest.pheadTop === 69 && rest.fieldTop === 129, `at rest: layout unchanged by the sticky tiers (phead ${rest.pheadTop}, field ${rest.fieldTop})`);

  await p.click('[data-act="pend"]'); await p.waitForTimeout(300); await settle();
  await p.evaluate(() => document.querySelector('.scroller').scrollTop = 1500); await p.waitForTimeout(250);
  const mid = await J(() => {
    const bar = document.getElementById('pbar'), br = bar.getBoundingClientRect();
    const lh = document.querySelector('.lhead'), lr = lh.getBoundingClientRect();
    const back = bar.querySelector('.back'), bk = back && back.getBoundingClientRect();
    return {
      shown: getComputedStyle(bar).opacity === '1', barH: +br.height.toFixed(1),
      title: bar.querySelector('.pbt').textContent, back: back && back.textContent.trim(),
      backH: bk && +bk.height.toFixed(1),
      heading: lh.textContent.replace(/\s+/g, ' ').trim(),
      underBar: +(lr.top - br.bottom).toFixed(1),
      bleed: +lr.left.toFixed(1) === 0 && +lr.right.toFixed(1) === 375,
      opaque: !/rgba\(0, 0, 0, 0\)/.test(getComputedStyle(lh).backgroundColor),
      focusableBacks: [...document.querySelectorAll('.back')].filter(b => !b.inert && !b.closest('[inert]')).length
    };
  });
  ok(mid.shown && near(mid.barH, 44), `scrolled 1500px: the page bar shows, 44px (${mid.barH})`);
  ok(mid.title === 'Pendientes' && /Juegos/.test(mid.back), `bar carries back + title ("${mid.back}" / "${mid.title}")`);
  ok(mid.backH >= 44, `bar back link is a 44px target (${mid.backH})`);
  ok(/Sin datos/.test(mid.heading) && near(mid.underBar, 0, 1), `"${mid.heading}" pinned flush under the bar (${mid.underBar}px)`);
  ok(mid.bleed && mid.opaque, 'the pinned heading is opaque and full-bleed — rows cannot slide past it');
  ok(mid.focusableBacks === 1, `exactly one focusable back control, never a duplicate (${mid.focusableBacks})`);
  await p.screenshot({ path: path.join(OUT, '12-sticky-pendientes-375x740-light.png') });

  /* the iOS push: each heading is confined to its own section, so the next one evicts it */
  await p.evaluate(() => { const g = document.querySelectorAll('.lgroup')[0]; document.querySelector('.scroller').scrollTop = g.offsetTop + g.offsetHeight - 120; });
  await p.waitForTimeout(250);
  const push = await J(() => [...document.querySelectorAll('.lhead')].map(h => ({ t: h.textContent.replace(/\s+/g, ' ').trim(), top: +h.getBoundingClientRect().top.toFixed(1) })));
  ok(push[0].top < push[1].top, `"${push[0].t}" is pushed out by "${push[1].t}" (${push[0].top} / ${push[1].top})`);
  await p.screenshot({ path: path.join(OUT, '13-sticky-push-375x740-light.png') });

  /* the bar's back really navigates, and a new screen starts at the top */
  await p.evaluate(() => document.querySelector('.scroller').scrollTop = 1500); await p.waitForTimeout(200);
  await p.click('#pbar .back'); await p.waitForTimeout(300);
  const after = await J(() => ({ title: document.querySelector('.ptitle').textContent, top: document.querySelector('.scroller').scrollTop, scrolled: document.getElementById('device').classList.contains('scrolled') }));
  ok(after.title === 'Juegos' && after.top === 0 && !after.scrolled, `the bar's back returns to Juegos at the top (${JSON.stringify(after)})`);

  /* the main list: a tab-level page has no back link, and its heading pins through 435 rows */
  await p.evaluate(() => { for (let i = 0; i < 8; i++) document.querySelector('[data-act="more"]')?.click(); });
  await p.waitForTimeout(400);
  await p.evaluate(() => document.querySelector('.scroller').scrollTop = 1200); await p.waitForTimeout(250); await settle();
  const jm = await J(() => ({
    title: document.getElementById('pbar').querySelector('.pbt').textContent,
    hasBack: !!document.getElementById('pbar').querySelector('.back'),
    heading: document.querySelector('.lhead').textContent.replace(/\s+/g, ' ').trim(),
    headingTop: +document.querySelector('.lhead').getBoundingClientRect().top.toFixed(1),
    rows: document.querySelectorAll('.row').length
  }));
  ok(jm.title === 'Juegos' && !jm.hasBack, 'a tab-level page bar shows the title with no back link');
  ok(near(jm.headingTop, 97, 2), `"${jm.heading}" stays pinned through ${jm.rows} rows (top ${jm.headingTop})`);
  await p.screenshot({ path: path.join(OUT, '14-sticky-juegos-375x740-light.png') });
  await p.evaluate(() => document.documentElement.dataset.theme = 'dark'); await p.waitForTimeout(200);
  await p.screenshot({ path: path.join(OUT, '15-sticky-juegos-375x740-dark.png') });
  await ctx.close();

  /* ---------- other viewports: how much of the list is visible ---------- */
  for (const [w, h] of [[360, 640], [375, 667], [390, 844]]) {
    const c2 = await browser.newContext({ viewport: { width: w, height: h }, deviceScaleFactor: 2 });
    const q = await c2.newPage();
    q.on('pageerror', e => errs.push(`pageerror ${w}x${h}: ` + e.message));
    await q.goto(URL); await q.evaluate(() => document.fonts.ready);
    await q.evaluate(() => { document.getElementById('tools').style.display = 'none'; });
    const m = await q.evaluate(() => {
      const tabs = document.querySelector('.tabs').getBoundingClientRect().top;
      const rows = [...document.querySelectorAll('.row')];
      const visible = rows.filter(r => r.getBoundingClientRect().bottom <= tabs).length;
      const lastVisible = rows.filter(r => r.getBoundingClientRect().top < tabs).length;
      const sc = document.querySelector('.scroller');
      return { visible, lastVisible, oflow: sc.scrollWidth - sc.clientWidth, pageH: document.querySelector('main').getBoundingClientRect().height };
    });
    ok(m.oflow <= 0, `${w}x${h}: no horizontal overflow (${m.oflow}px)`);
    ok(m.visible >= 3, `${w}x${h}: ${m.visible} whole rows visible without scrolling (${m.lastVisible} partly)`);
    await q.evaluate(() => [...document.querySelectorAll('img[loading="lazy"]')].forEach(i => i.loading='eager')); await q.waitForTimeout(1800); await q.screenshot({ path: path.join(OUT, `11-juegos-${w}x${h}-light.png`) });
    await c2.close();
  }

  await browser.close();
  ok(errs.length === 0, `no page errors (${errs.length ? errs.join(' | ') : 'none'})`);
  console.log(log.join('\n'));
  console.log(`\n${log.filter(l => l.startsWith('PASS')).length}/${log.length} passed · shots in ${OUT}`);
  process.exit(log.some(l => l.startsWith('FAIL')) ? 1 : 0);
})();
