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
  /* Colour sampling MUST park the cursor off-canvas first. A click leaves the mouse on the element it hit, and
     `.lhead:hover` swaps --color-surface for --color-surface-2 — which once split one contiguous tinted mass into
     two and failed a real check. Verified: 220px reads 241,236,253 parked and 222,212,243 hovered. */
  const cool = async () => { await p.mouse.move(-50, -50); await p.waitForTimeout(150); };
  const settle = async (pg = p) => {
    await pg.evaluate(() => [...document.querySelectorAll('img[loading="lazy"]')].forEach(i => i.loading = 'eager'));
    await pg.waitForFunction(() => [...document.querySelectorAll('img.cov')].every(i => i.complete), null, { timeout: 8000 }).catch(() => {});
    await pg.waitForTimeout(250);
  };
  await settle();

  /* ---------- decision 17: ONE LIST, one section anatomy ----------
     The page is a single continuous list whose sections hold different content. Every header is the same
     caption — never a control — which is what removes the whole band negotiation decisions 10-16 were spent on:
     a caption cannot be mistaken for a row, so it needs no caret, no 44px target and no tonal band. */
  const groups = await J(() => [...document.querySelectorAll('.lhead')].map(h => ({
    name: h.querySelector('.ln').textContent,
    count: +h.querySelector('.cnt').textContent,
    h: +h.getBoundingClientRect().height.toFixed(1)
  })));
  ok(groups.length === 3, `three sections (${groups.map(g => g.name).join(', ')})`);
  ok(groups.map(g => g.name).join('|') === 'Sin datos|Borradores|Juegos del club', `exceptions first, catalog last (${groups.map(g => g.name).join(' > ')})`);
  const sum = groups.reduce((a, g) => a + g.count, 0);
  ok(sum === 435, `the sections PARTITION the catalog: ${groups.map(g => g.count).join(' + ')} = ${sum}`);

  /* the load-bearing assertion of decision 17, kept through decision 18: ONE anatomy. Everything that decides
     whether two headers read as the same kind of thing — fill, rank, colour, height, keyline — must be identical
     across all three. Decision 18 adds a caret to the two that collapse, which is the affordance TELLING you they
     collapse; it is deliberately excluded here and asserted separately below. */
  const anat = await J(() => [...document.querySelectorAll('.lhead')].map(h => {
    const ln = h.querySelector('.ln'), c = getComputedStyle(ln);
    const g = document.createRange(); g.selectNodeContents(ln);
    return [getComputedStyle(h).backgroundColor, c.fontSize + '/' + c.fontWeight, c.color,
      +h.getBoundingClientRect().height.toFixed(1), +g.getBoundingClientRect().left.toFixed(1)].join('|');
  }));
  ok(new Set(anat).size === 1, `every section header is the SAME component (${new Set(anat).size} anatomy: ${anat[0]})`);
  ok(/\|15px\/600\|/.test(anat[0]), 'every section carries D-19j\'s list-section rank, 15/600 (decision 20)');
  ok(/^rgba\(0, 0, 0, 0\)\|/.test(anat[0]), 'no section is tinted at rest — the fill is for pinning only');

  /* decision 18 — the two EXCEPTION sections close at rest so the catalog is not buried behind them; the body
     section still never collapses, so decision 15's empty page stays unreachable. The caret is the ONLY thing
     that differs, and it sits inline after the count — not leading (which would put a hole back in the x=16
     column) and not at x=339 (which D-19i reserves for "opens a page"). */
  const disc = await J(() => {
    const heads = [...document.querySelectorAll('.lhead')];
    const row = document.querySelector('.row .chev');
    return heads.map(h => ({
      name: h.querySelector('.ln').textContent, tag: h.tagName,
      caret: !!h.querySelector('.caret'), open: h.getAttribute('aria-expanded'),
      caretLeft: h.querySelector('.caret') ? +h.querySelector('.caret').getBoundingClientRect().left.toFixed(1) : null,
      rowChev: +row.getBoundingClientRect().left.toFixed(1),
      hit: +Math.max(h.getBoundingClientRect().height, parseFloat(getComputedStyle(h, '::after').height) || 0).toFixed(1)
    }));
  });
  ok(disc[0].open === 'false' && disc[1].open === 'false', `"Sin datos" and "Borradores" are CLOSED at rest (${disc[0].open}, ${disc[1].open})`);
  ok(disc[0].caret && disc[1].caret && !disc[2].caret, 'only the sections that collapse carry a caret — the body section has none');
  ok(disc[2].tag === 'SPAN' && disc[2].open === null, `the body section is not a control (<${disc[2].tag.toLowerCase()}>), so it cannot strand a header over an empty page`);
  ok(disc.filter(d => d.caret).every(d => d.caretLeft < d.rowChev - 100), `the caret is inline, never in the row-chevron slot (${disc.filter(d => d.caret).map(d => d.caretLeft).join(', ')} vs ${disc[0].rowChev})`);
  ok(disc.filter(d => d.caret).every(d => d.hit >= 44), `a collapsible caption still meets the 44px touch floor (${disc.filter(d => d.caret).map(d => d.hit).join(', ')})`);
  const catTop = await J(() => {
    const sc = document.querySelector('.scroller').getBoundingClientRect();
    return +(document.querySelector('.lgroup.main .lhead').getBoundingClientRect().top - sc.top).toFixed(0);
  });
  ok(catTop < 260, `the catalog is reachable without scrolling past the exceptions (${catTop}px from the top, was 3270)`);

  const secRows = await J(() => [...document.querySelectorAll('.lgroup')].map(g => g.querySelectorAll('.row').length));
  ok(secRows[2] > 0, `the body section always shows its rows (${secRows[2]})`);

  /* sections butt together: no gap, so there is no pitch to read as a stripe (decision 11's problem, dissolved) */
  const seams = await J(() => {
    const secs = [...document.querySelectorAll('.lgroup')];
    const out = [];
    for (let i = 1; i < secs.length; i++) out.push(+(secs[i].getBoundingClientRect().top - secs[i - 1].getBoundingClientRect().bottom).toFixed(1));
    return out;
  });
  ok(seams.every(g => Math.abs(g) < 1), `sections butt together, no gaps (${seams.join(', ')})`);

  /* two text left edges still: every caption at 16, every row name at 68 */
  const edges = await J(() => {
    const L = e => { const g = document.createRange(); g.selectNodeContents(e); return +g.getBoundingClientRect().left.toFixed(1); };
    const heads = [...document.querySelectorAll('.lhead')], row = document.querySelector('.row');
    return [...new Set([L(document.querySelector('.ptitle')), ...heads.map(h => L(h.querySelector('.ln'))),
      +row.querySelector('.cov').getBoundingClientRect().left.toFixed(1), L(row.querySelector('.name'))])].sort((a, b) => a - b);
  });
  ok(edges.length === 2 && near(edges[0], 16) && near(edges[1], 68), `exactly two text left edges (${edges.join(' / ')})`);

  /* a caption must still be legible against a row it is NOT: rank and colour both differ from a row name */
  const sep = await J(() => {
    const t = e => { const c = getComputedStyle(e); return c.fontSize.replace('px', '') + '/' + c.fontWeight; };
    const L = e => { const g = document.createRange(); g.selectNodeContents(e); return +g.getBoundingClientRect().left.toFixed(1); };
    const hn = document.querySelector('.lhead .ln'), rn = document.querySelector('.row .name'), sb = document.querySelector('.row .sub');
    return { head: t(hn), row: t(rn), headColor: getComputedStyle(hn).color, rowColor: getComputedStyle(rn).color,
      headWeight: +getComputedStyle(hn).fontWeight, rowWeight: +getComputedStyle(rn).fontWeight,
      headSize: parseFloat(getComputedStyle(hn).fontSize), rowSize: parseFloat(getComputedStyle(rn).fontSize),
      subSize: parseFloat(getComputedStyle(sb).fontSize), subColor: getComputedStyle(sb).color,
      headLeft: L(hn), rowLeft: L(rn),
      headCover: !!document.querySelector('.lhead .cov'), rowCover: !!document.querySelector('.row .cov'),
      headBleed: +document.querySelector('.lhead').getBoundingClientRect().width.toFixed(1) };
  });
  /* decision 20 — a section and a row now share size and colour by design (D-19j puts them adjacent), so the
     separation rests on the three things that actually differ. Decision 10's confusion was a 44px CONTROL with a
     trailing icon in the row-chevron slot; none of that exists, but assert the differentiators anyway so a future
     change cannot quietly erase them. */
  ok(sep.head !== sep.row, `a section outweighs its rows (${sep.head} vs ${sep.row})`);
  ok(sep.headWeight > sep.rowWeight, `by weight (${sep.headWeight} vs ${sep.rowWeight})`);
  ok(sep.headLeft === 16 && sep.rowLeft === 68, `by keyline (${sep.headLeft} vs ${sep.rowLeft})`);
  ok(!sep.headCover && sep.rowCover, 'and by the 40px cover a row has and a section does not');
  /* the inversion that prompted decision 20 must not come back: a section must never be quieter than a row, nor
     read as a row's second line */
  ok(sep.headSize >= sep.rowSize, `a section is never smaller than the rows it heads (${sep.headSize} vs ${sep.rowSize})`);
  ok(!(sep.headSize === sep.subSize && sep.headColor === sep.subColor), `nor identical to a row's second line (${sep.headSize}/${sep.headColor} vs ${sep.subSize}/${sep.subColor})`);
  ok(near(sep.headBleed, 375, 1), `the caption is full-bleed so it can pin opaquely (${sep.headBleed})`);

  /* no Pendientes page and no badge — decision 8 deleted them and decision 17 keeps them gone */
  ok(await J(() => !document.querySelector('.badge') && !document.querySelector('[data-act="pend"]')), 'the Pendientes page and its badge are gone (decision 8 replaces D-19g here)');
  ok(await J(() => document.querySelectorAll('.hacts .ibtn').length === 1 && document.querySelector('.hacts .ibtn').dataset.act === 'add'), 'the header keeps only "+"');

  /* ---------- rhythm at rest ---------- */
  const phead = await box('.phead'), field = await box('.sfield input');
  const lh0 = await textBox('.lhead .ln');
  ok(near(field.h, 48), `main control is a 48px field (${field.h.toFixed(1)})`);
  ok(near(field.t - phead.b, 16, 1.5), `title row -> field 16, as 069 raised (${(field.t - phead.b).toFixed(1)})`);
  /* decision 11 measures to the BAND EDGE, not the heading text: decision 10 made the box visible, so the box
     is now what the eye reads. Target 24 to the band, 0 between the joined work bands, 32 to the catalog. */
  /* decision 17 — the gap system decision 11 built (24 / 0 / 32 / 0 between a work block and a catalog) is
     dissolved: there are no blocks, so there is nothing to space. What must hold instead is that the list is
     continuous and that NOTHING is tinted at rest — the fill exists only for a pinned header. */
  const flow = await J(() => {
    const f = document.querySelector('.sfield input').getBoundingClientRect();
    const h0 = document.querySelector('.lhead').getBoundingClientRect();
    const seen = [];
    for (let y = 150; y < 560; y++) {
      const el = document.elementFromPoint(300, y);
      const bg = el ? getComputedStyle(el).backgroundColor : '-';
      const last = seen[seen.length - 1];
      if (last && last.bg === bg) last.b = y; else seen.push({ t: y, b: y, bg });
    }
    const plain = ['rgba(0, 0, 0, 0)', 'rgb(255, 255, 255)'];
    return { fieldToFirst: +(h0.top - f.bottom).toFixed(1), tinted: seen.filter(r => !plain.includes(r.bg)).map(r => `${r.t}..${r.b}`) };
  });
  ok(near(flow.fieldToFirst, 24, 4), `the search leads into the list (${flow.fieldToFirst})`);
  ok(flow.tinted.length === 0, `NOTHING is tinted at rest — one list, no bands (${flow.tinted.join(', ') || 'none'})`);

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
  ok(rowsInfo.n === 50, `at rest only the open body section renders rows (${rowsInfo.n})`);
  ok(near(rowsInfo.h, 64, 1.5), `game row 64px (${rowsInfo.h})`);
  ok(!rowsInfo.anySinDatos && !rowsInfo.anyBorrador, 'a row never repeats its group\'s state ("Sin datos" x49 under a heading saying it was noise)');
  ok(rowsInfo.chev, 'a game row keeps its chevron — it opens the editor (D-19i)');

  /* ---------- decision 18: the exceptions open on demand ----------
     No expand/collapse existed under decision 17; decision 18 brings it back for the two exception sections
     only. Opening one must reveal its rows AND leave the tapped heading exactly where the finger left it. */
  const shutAtRest = await J(() => [...document.querySelectorAll('.lgroup')].map(g => g.querySelectorAll('.row').length));
  ok(shutAtRest[0] === 0 && shutAtRest[1] === 0, `both exception sections are closed at rest (${shutAtRest[0]}, ${shutAtRest[1]} rows)`);
  ok(await J(() => document.querySelectorAll('.hint').length === 0), 'no hint exists at rest — decision 19 costs the resting list nothing');
  ok(shutAtRest[2] === 50, `the catalog still pages 50 at a time (${shutAtRest[2]})`);
  const beforeTop = await J(() => +document.querySelector('[data-g="gap"]').getBoundingClientRect().top.toFixed(1));
  await p.click('[data-g="gap"]'); await p.waitForTimeout(350); await settle();
  const openedInfo = await J(() => ({
    rows: document.querySelector('[data-g="gap"]').closest('.lgroup').querySelectorAll('.row').length,
    expanded: document.querySelector('[data-g="gap"]').getAttribute('aria-expanded'),
    headTop: +document.querySelector('[data-g="gap"]').getBoundingClientRect().top.toFixed(1)
  }));
  ok(openedInfo.expanded === 'true' && openedInfo.rows === 49, `opening "Sin datos" reveals its 49 rows (${openedInfo.rows})`);
  ok(near(openedInfo.headTop, beforeTop, 2), `the tapped heading stays put — opening never scrolls the page (${beforeTop} -> ${openedInfo.headTop})`);
  /* decision 19 — the hint returns, but ONLY inside an opened section, and it must land on the 16 keyline
     rather than introducing a third text edge. At rest it must not exist at all. */
  const hint = await J(() => {
    const grp = document.querySelector('[data-g="gap"]').closest('.lgroup');
    const h = grp.querySelector('.hint');
    const L = e => { const g = document.createRange(); g.selectNodeContents(e); return +g.getBoundingClientRect().left.toFixed(1); };
    return { text: h && h.textContent.trim(), left: h ? L(h) : null,
      type: h ? getComputedStyle(h).fontSize.replace('px', '') + '/' + getComputedStyle(h).fontWeight : null,
      edges: [...new Set([16, ...[...document.querySelectorAll('.lhead .ln')].map(L), ...(h ? [L(h)] : []),
        L(grp.querySelector('.row .name'))])].sort((a, b) => a - b) };
  });
  ok(/sin tapa/.test(hint.text || ''), `an opened section carries its hint ("${hint.text}")`);
  ok(near(hint.left, 16), `the hint lands on the 16 keyline (${hint.left})`);
  ok(hint.edges.length === 2 && near(hint.edges[0], 16) && near(hint.edges[1], 68), `still two text edges with the hint showing (${hint.edges.join(' / ')})`);
  await p.screenshot({ path: path.join(OUT, '02-section-open-375x740-light.png') });
  await p.click('[data-g="gap"]'); await p.waitForTimeout(300); await settle();
  ok(await J(() => document.querySelector('[data-g="gap"]').getAttribute('aria-expanded') === 'false'), 'and it closes again, leaving the page as it was');

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
  /* decision 17 — whichever section header is currently pinned gains its fill; at rest none of them has one.
     This is the one moment a caption must terminate itself over the rows sliding under it (without the fill the
     pinned header is opaque but edgeless, with a half-cut cover directly beneath — measured while comparing the
     no-tint variant). The catalog is the LAST section now, so this must test whatever is pinned, not the catalog. */
  const pinned = await J(() => {
    const want = getComputedStyle(document.getElementById('device')).getPropertyValue('--color-surface').trim();
    const px = s => { const d = document.createElement('div'); d.style.color = s; document.body.appendChild(d); const c = getComputedStyle(d).color; d.remove(); return c; };
    const on = [...document.querySelectorAll('.lhw')].filter(w => w.classList.contains('pinned'));
    return { count: on.length, name: on[0] ? on[0].querySelector('.ln').textContent : null,
      bg: on[0] ? getComputedStyle(on[0].querySelector('.lhead')).backgroundColor : null, want: px(want) };
  });
  ok(pinned.count === 1, `exactly one section header is pinned while scrolling (${pinned.count}: ${pinned.name})`);
  ok(pinned.bg === pinned.want, `the pinned header gains its fill so it terminates over the rows (${pinned.bg})`);
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
