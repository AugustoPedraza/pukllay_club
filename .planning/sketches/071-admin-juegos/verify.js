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
  /* The anatomy that decides whether two headers read as the same KIND of thing is the ink: fill, rank, colour,
     keyline. Height was folded in until decision 21, which deliberately gives the FIRST section less leading air
     because the 48px search field above it already separates it, while the others follow a label or rows. That
     is spacing, not identity — so it is asserted separately below rather than dropped. */
  const anat = await J(() => [...document.querySelectorAll('.lhead')].map(h => {
    const ln = h.querySelector('.ln'), c = getComputedStyle(ln);
    const g = document.createRange(); g.selectNodeContents(ln);
    return [getComputedStyle(h).backgroundColor, c.fontSize + '/' + c.fontWeight, c.color,
      +g.getBoundingClientRect().left.toFixed(1)].join('|');
  }));
  ok(new Set(anat).size === 1, `every section header is the SAME component (${new Set(anat).size} anatomy: ${anat[0]})`);
  const air = await J(() => [...document.querySelectorAll('.lhead')].map(h => parseFloat(getComputedStyle(h).paddingTop)));
  ok(new Set(air.slice(1)).size === 1, `leading air is uniform across every section after the first (${air.slice(1).join(', ')})`);
  ok(air[0] < air[1], `and the first section is deliberately tighter — the search field above it already separates (${air[0]} vs ${air[1]})`);
  /* decision 28 — the shared rank is VERSALITA, 14/600 uppercase. What must hold is that all three carry the
     SAME one; whether that rank has enough presence against a row is asserted separately, in cap height. */
  ok(/\|14px\/600\|/.test(anat[0]), 'every section carries the same rank, 14/600 (decision 28)');
  ok(await J(() => [...document.querySelectorAll('.lhead .ln')].every(n => getComputedStyle(n).textTransform === 'uppercase')),
    'and every section label is uppercase — case is what makes it a different KIND of text from a row name');
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

  /* ---------- decision 25 — the caret is a DIFFERENT GLYPH, not just a different x ----------
     Decision 18 used chevR and separated it from the row chevron by POSITION alone. Measured, the two paths were
     byte-identical (`M9 5l7 7-7 7`) — so the page carried four "›" meaning two different things, and decision
     10's own rule ("a disclosure triangle, never a trailing ›, which under D-19i means opens a page") had been
     contradicted while its position fix was kept. Down means expand, up means collapse. */
  const glyph = await J(() => {
    const d = e => [...e.querySelectorAll('path')].map(x => x.getAttribute('d')).join(';');
    const caret = document.querySelector('.lhead .caret svg'), rowChev = document.querySelector('.row .chev svg');
    return { caret: d(caret), row: d(rowChev),
      closedRot: getComputedStyle(document.querySelector('.lhead[aria-expanded="false"] .caret')).transform };
  });
  ok(glyph.caret !== glyph.row, `the caret is not the row chevron's glyph (${glyph.caret} vs ${glyph.row})`);
  ok(/M5 9l7 7 7-7/.test(glyph.caret), `it is a chevron-DOWN — "this expands" (${glyph.caret})`);
  ok(glyph.closedRot === 'none', `and it is unrotated while closed (${glyph.closedRot})`);
  await J(() => document.querySelector('.lhead.tap').click()); await p.waitForTimeout(220);
  const openRot = await J(() => getComputedStyle(document.querySelector('.lhead[aria-expanded="true"] .caret')).transform);
  ok(openRot === 'matrix(-1, 0, 0, -1, 0, 0)', `open, it flips 180 to a chevron-UP — "collapse this" (${openRot})`);
  /* the whole point: no glyph on this page ever points right except the one D-19i reserves */
  const rights = await J(() => [...document.querySelectorAll('.lhead .caret svg path, .row .chev svg path')]
    .map(x => x.getAttribute('d')).filter(d => /M9 5l7 7-7 7/.test(d)).length);
  const chevs = await J(() => document.querySelectorAll('.row .chev').length);
  ok(rights === chevs, `every right-pointing chevron on the page is a row's "opens a page" (${rights} of ${chevs})`);
  await J(() => document.querySelector('.lhead.tap').click()); await p.waitForTimeout(220);
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
  /* decision 21 — proximity must not invert. Measured TEXT-TO-TEXT, because the headers are transparent: a box
     gap here is invisible to a reader and reported every variant as identical. A label must sit closer to the
     rows it heads than to the label before it, or three labels read as one block. */
  const prox = await J(() => {
    const T = e => { const g = document.createRange(); g.selectNodeContents(e); const r = g.getBoundingClientRect(); return { t: r.top, b: r.bottom }; };
    const ln = [...document.querySelectorAll('.lhead .ln')].map(T);
    const firstRow = T(document.querySelector('.lgroup.main .row .name'));
    return { between: +(ln[1].t - ln[0].b).toFixed(0), toRows: +(firstRow.t - ln[2].b).toFixed(0) };
  });
  ok(prox.between > prox.toRows, `a label sits closer to its own rows than to the label above it (${prox.between} above vs ${prox.toRows} below)`);
  ok(prox.between / prox.toRows >= 2, `and by a clear ratio, not a hair (${(prox.between / prox.toRows).toFixed(1)}:1)`);

  /* two text left edges still: every caption at 16, every row name at 68 */
  const edges = await J(() => {
    const L = e => { const g = document.createRange(); g.selectNodeContents(e); return +g.getBoundingClientRect().left.toFixed(1); };
    const heads = [...document.querySelectorAll('.lhead')], row = document.querySelector('.row');
    return [...new Set([+document.querySelector('.search .sfield').getBoundingClientRect().left.toFixed(1), ...heads.map(h => L(h.querySelector('.ln'))),
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
  /* decision 28 makes decision 20's inversion guard MORE PRECISE rather than weaker. Decision 20 wrote it as
     font-size ("a section is never smaller than its rows"), which is the wrong measurement for uppercase: a
     14px capital is taller than a 15px lowercase. Restated as CAP HEIGHT, which is what the eye compares.
     Measured: versalita 12 and 13 both render a 9px cap and 14 and 15 both render 11px — the font pairs them at
     these sizes — so the scale has only two real steps and 14 is the cheaper of the taller pair. */
  const caps = await J(() => {
    const cv = document.createElement('canvas'), x = cv.getContext('2d');
    const of = el => { const c = getComputedStyle(el); return { px: parseFloat(c.fontSize), w: c.fontWeight, fam: c.fontFamily }; };
    const cap = f => { x.font = `${f.w} ${f.px}px ${f.fam}`; return +x.measureText('H').actualBoundingBoxAscent.toFixed(2); };
    const xh = f => { x.font = `${f.w} ${f.px}px ${f.fam}`; return +x.measureText('x').actualBoundingBoxAscent.toFixed(2); };
    const h = of(document.querySelector('.lhead .ln')), r = of(document.querySelector('.row .name'));
    return { head: cap(h), rowCap: cap(r), rowX: xh(r) };
  });
  ok(caps.head >= caps.rowCap, `a section's capitals are at least a row name's capitals (${caps.head} vs ${caps.rowCap})`);
  ok(caps.head / caps.rowX >= 1.25, `and clearly outweigh the lowercase body the eye actually scans (${(caps.head / caps.rowX * 100).toFixed(0)}%)`);
  ok(!(sep.headSize === sep.subSize && sep.headColor === sep.subColor), `nor identical to a row's second line (${sep.headSize}/${sep.headColor} vs ${sep.subSize}/${sep.subColor})`);
  ok(near(sep.headBleed, 375, 1), `the caption is full-bleed so it can pin opaquely (${sep.headBleed})`);

  /* no Pendientes page and no badge — decision 8 deleted them and decision 17 keeps them gone */
  ok(await J(() => !document.querySelector('.badge') && !document.querySelector('[data-act="pend"]')), 'the Pendientes page and its badge are gone (decision 8 replaces D-19g here)');
  ok(await J(() => document.querySelectorAll('main .ibtn').length === 1 && document.querySelector('main .ibtn').dataset.act === 'add'), 'the page keeps exactly one icon button, "+"');

  /* ---------- rhythm at rest ---------- */
  const field = await box('.sfield input');
  const lh0 = await textBox('.lhead .ln');
  ok(near(field.h, 48), `main control is a 48px field (${field.h.toFixed(1)})`);

  /* ---------- decision 22 — a search-first tab root has no resting title ----------
     The chrome was a FIXED 265px, so it read 51% of usable height on a 360x640 (three games), not the 43% the
     handoff quoted from the roomiest phone. The <h1> is dropped and the + moves beside the field. */
  const d22 = await J(() => {
    const sc = document.querySelector('.scroller').getBoundingClientRect();
    const f = document.querySelector('.sfield input').getBoundingClientRect();
    const sf = document.querySelector('.sfield').getBoundingClientRect();
    const add = document.querySelector('main .ibtn').getBoundingClientRect();
    const h1 = document.querySelector('main h1');
    return { ptitle: !!document.querySelector('.ptitle'), phead: !!document.querySelector('.phead'),
      h1text: h1 && h1.textContent, h1sr: !!(h1 && h1.classList.contains('sr')),
      h1w: h1 ? +h1.getBoundingClientRect().width.toFixed(0) : null,
      air: +(f.top - sc.top).toFixed(1),
      addW: +add.width.toFixed(0), addH: +add.height.toFixed(0),
      addRight: +add.right.toFixed(0), gap: +(add.left - sf.right).toFixed(0),
      fieldW: +sf.width.toFixed(0) };
  });
  ok(!d22.ptitle && !d22.phead, 'no resting page title — the tab bar names the page (decision 7, applied at rest)');
  /* dropping the VISIBLE title must not drop the heading from the accessibility tree */
  ok(d22.h1text === 'Juegos' && d22.h1sr && d22.h1w <= 1, `the h1 survives for screen readers, not for the eye (.sr, ${d22.h1w}px wide)`);
  ok(near(d22.air, 24, 1.5), `the field leads the page on 24px of air (${d22.air})`);
  ok(d22.addW === 44 && d22.addH === 44, `+ still meets the touch floor (${d22.addW}x${d22.addH})`);
  ok(near(d22.addRight, 371, 1.5), `+ keeps the header icon's right edge (${d22.addRight})`);
  ok(d22.gap === 8, `+ sits 8px clear of the field (${d22.gap})`);
  ok(d22.fieldW >= 280, `the field keeps a usable width beside it (${d22.fieldW}px)`);
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
    return { lhead: g('.lhead'), name: g('.row .name'), field: g('.sfield input'), sub: g('.row .sub') }; });
  /* D-19j, minus the title rank decision 22 removed from this page: 48px field > section 15/600 > row 15/400 */
  ok(ranks.lhead === '14/600' && ranks.name === '15/400' && ranks.field === '16/400',
    `type ranks hold (field ${ranks.field}, heading ${ranks.lhead}, row ${ranks.name}, year ${ranks.sub})`);
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
      /* decision 29 — the fill lives on the caption's ::before band, never on the caption itself, so read it
         there. Reading `.lhead` directly is what this check used to do and it now reports transparent by
         design; the band's geometry is asserted separately, in the every-state guard above. */
      bg: on[0] ? getComputedStyle(on[0].querySelector('.lhead'), '::before').backgroundColor : null, want: px(want) };
  });
  ok(pinned.count === 1, `exactly one section header is pinned while scrolling (${pinned.count}: ${pinned.name})`);
  ok(pinned.bg === pinned.want, `the pinned header gains its fill so it terminates over the rows (${pinned.bg})`);

  /* ---------- decision 27 — the pinned band's GEOMETRY, not just its identity ----------
     Reported from a real device: "when I scroll, the background color isn't aligned, making the text be more
     aligned to the bottom of what it shows". Measured, exactly right — 26.0px of empty tint above the text and
     0.5 below, because decision 21's `padding-top: 26; padding-bottom: 0` (which makes the RESTING air) becomes
     visible geometry the instant the caption gains a fill. Every earlier pinned check asserted WHICH header was
     pinned and never what it looked like, so a transparent-state measurement shipped as a tinted-state defect.
     The band must centre its ink AND keep its box height, so the sticky element's flow slot never changes. */
  const band = await J(() => {
    const hw = [...document.querySelectorAll('.lhw')].find(w => w.classList.contains('pinned'));
    const h = hw.querySelector('.lhead'), ln = h.querySelector('.ln');
    const box = h.getBoundingClientRect();
    const g = document.createRange(); g.selectNodeContents(ln);
    const ink = g.getBoundingClientRect();
    const pb = getComputedStyle(h, '::before'), own = getComputedStyle(h);
    const bt = box.top + (parseFloat(pb.top) || 0), bb = box.bottom - (parseFloat(pb.bottom) || 0);
    return { above: +(ink.top - bt).toFixed(1), below: +(bb - ink.bottom).toFixed(1),
      h: +(bb - bt).toFixed(1), boxH: +box.height.toFixed(1),
      padT: own.paddingTop, padB: own.paddingBottom, ptVar: own.getPropertyValue('--pt').trim() };
  });
  ok(Math.abs(band.above - band.below) <= 1.5, `the pinned band centres its text (${band.above} above, ${band.below} below)`);
  ok(band.above >= 6, `with real breathing room, not a hairline (${band.above}px)`);
  /* decision 31 — the anti-jump invariant is about the BOX, not the band. The caption's padding no longer
     changes between states, so its flow slot cannot change; the band is a pseudo-element whose thickness is
     free. Assert the thing that actually prevents a jump. */
  /* Comparing two DIFFERENT sections' boxes proves nothing — decision 21 makes the first one deliberately
     shorter. The invariant is that pinning changes no padding at all, which is what keeps the flow slot fixed. */
  ok(band.padT === band.ptVar && band.padB === '0px',
    `pinning changes no padding, so the flow slot cannot move (top ${band.padT} = --pt ${band.ptVar}, bottom ${band.padB})`);

  /* ---------- decision 31 — every pinned bar is the SAME height ----------
     The bar used to be the caption's own box, so it inherited decision 21's deliberate first-section exception
     (--pt 14 vs 26) and the bar under SIN DATOS measured 32.2 against JUEGOS DEL CLUB's 44.2 — reported from the
     device, after scrolling one section and then the other. That exception is right at rest and meaningless in
     a bar. Only ever asserting a bar against ITS OWN resting height could never catch this: the missing
     assertion was across sections, not across states. */
  const bars = await J(async () => {
    const sc = document.querySelector('.scroller');
    document.querySelectorAll('.lhead.tap').forEach(h => { if (h.getAttribute('aria-expanded') !== 'true') h.click(); });
    await new Promise(r => setTimeout(r, 260));
    const out = [];
    for (const name of ['Sin datos', 'Borradores', 'Juegos del club']) {
      const h = [...document.querySelectorAll('.lhead')].find(x => x.querySelector('.ln').textContent === name);
      sc.scrollTop = h.closest('.lgroup').offsetTop + 40;
      await new Promise(r => setTimeout(r, 220));
      const box = h.getBoundingClientRect(), pb = getComputedStyle(h, '::before');
      const t = box.top + (parseFloat(pb.top) || 0), b = box.bottom - (parseFloat(pb.bottom) || 0);
      out.push({ name, pinned: h.closest('.lhw').classList.contains('pinned'),
        pt: getComputedStyle(h).getPropertyValue('--pt').trim(), h: +(b - t).toFixed(1) });
    }
    return out;
  });
  ok(bars.every(b => b.pinned), `each section pins in turn (${bars.map(b => b.name).join(', ')})`);
  ok(new Set(bars.map(b => b.h)).size === 1, `every pinned bar is the same height, whatever the section's resting air (${bars.map(b => `${b.name} ${b.h} @--pt ${b.pt}`).join(' | ')})`);
  ok(near(bars[0].h, 44, 0.5), `and that height is the 44px bar (${bars[0].h})`);
  ok(new Set(bars.map(b => b.pt)).size > 1, `while the RESTING air still differs by section, as decision 21 intended (${[...new Set(bars.map(b => b.pt))].join(' / ')})`);
  await J(() => { document.querySelector('.scroller').scrollTop = 1000;
    document.querySelectorAll('.lhead.tap[aria-expanded="true"]').forEach(h => h.click()); });
  await p.waitForTimeout(260);

  /* ---------- decision 29 — EVERY state that draws must centre its ink ----------
     Decision 27 fixed the pinned band and stopped there, so hovering a caption still painted the same
     asymmetric box (14px of colour above the text, 1.2 below) — the defect survived in the state nobody had
     looked at, immediately after the note that named the general rule. The guard therefore has to enumerate
     the STATES, not the one that was reported: anything that draws a fill or a ring gets measured. */
  /* decision 30 — measure the CAP BLOCK, not the range rect. A Range's box is still a BOX: at 14/600 it is 17px
     tall inside an 18.2px content box, while the capitals are 11. Centring the range rect left the ink 0.6px
     high in every state — measurable, visible, and passed by the previous guard, which is how a band that looked
     wrong shipped green. The probe uses an "H" so it is glyph-independent: the descending tail of the J in
     "JUEGOS" must not drag the optical centre, and measuring the real text made the two states disagree by 2px
     and sent the first fix off with an inverted sign. */
  const capInk = `(h) => {
    const ln = h.querySelector('.ln');
    const g = document.createRange(); g.selectNodeContents(ln);
    const lb = g.getBoundingClientRect(), cs = getComputedStyle(ln);
    const x = document.createElement('canvas').getContext('2d');
    x.font = cs.fontWeight + ' ' + cs.fontSize + ' ' + cs.fontFamily;
    const cap = x.measureText('H').actualBoundingBoxAscent;
    const base = lb.top + x.measureText(ln.textContent).fontBoundingBoxAscent;
    return { top: base - cap, bottom: base, cap: cap };
  }`;
  await p.evaluate(src => { window.INK = eval(src); }, capInk);
  const drawnStates = await J(async () => {
    const out = [];
    const measure = (h, label) => {
      const ink = INK(h), box = h.getBoundingClientRect();
      const cs = getComputedStyle(h, '::before'), own = getComputedStyle(h);
      const top = box.top + (parseFloat(cs.top) || 0);
      const bot = box.bottom - (parseFloat(cs.bottom) || 0);
      const draws = cs.backgroundColor !== 'rgba(0, 0, 0, 0)' || own.backgroundColor !== 'rgba(0, 0, 0, 0)'
        || (cs.outlineStyle && cs.outlineStyle !== 'none');
      out.push({ label, draws, above: +(ink.top - top).toFixed(1), below: +(bot - ink.bottom).toFixed(1),
        h: +(bot - top).toFixed(1) });
    };
    const tap = document.querySelector('.lhead.tap');
    const pinnedHead = [...document.querySelectorAll('.lhw')].find(w => w.classList.contains('pinned'))?.querySelector('.lhead');
    measure(tap, 'rest');
    if (pinnedHead) measure(pinnedHead, 'pinned');
    return out;
  });
  /* hover and focus need real input, so they are driven rather than simulated */
  await p.hover('.lhead.tap'); await p.waitForTimeout(220);
  const hov = await J(() => {
    const h = document.querySelector('.lhead.tap');
    const ink = INK(h), box = h.getBoundingClientRect();
    const cs = getComputedStyle(h, '::before');
    const top = box.top + (parseFloat(cs.top) || 0), bot = box.bottom - (parseFloat(cs.bottom) || 0);
    return { label: 'hover', draws: cs.backgroundColor !== 'rgba(0, 0, 0, 0)',
      above: +(ink.top - top).toFixed(1), below: +(bot - ink.bottom).toFixed(1), h: +(bot - top).toFixed(1),
      inkTop: +ink.top.toFixed(1) };
  });
  await cool();
  const restInkTop = await J(() => +INK(document.querySelector('.lhead.tap')).top.toFixed(1));
  const states = [...drawnStates, hov].filter(s => s.draws);
  ok(states.length >= 2, `at least the pinned and hover fills are under test (${states.map(s => s.label).join(', ')})`);
  states.forEach(s => ok(Math.abs(s.above - s.below) <= 0.8,
    `${s.label}: the cap block is centred in what is drawn (${s.above} above, ${s.below} below, band ${s.h})`));
  /* and the fix must not move the label — a hover that shifts the text 13px is worse than the misalignment */
  ok(near(hov.inkTop, restInkTop, 0.6), `hovering does not move the label (${hov.inkTop} vs ${restInkTop} at rest)`);
  /* the caption's own background must stay transparent in every state: the band is the ::before, so any direct
     fill is a state someone added without the band, which is exactly how this defect returns */
  await p.hover('.lhead.tap'); await p.waitForTimeout(160);
  ok(await J(() => getComputedStyle(document.querySelector('.lhead.tap')).backgroundColor === 'rgba(0, 0, 0, 0)'),
    'the caption itself never carries a background — the band is always the ::before');
  await cool();
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
  /* decision 22 — the + shortened the field, so the dropdown is anchored INSIDE .sfield at left:0/right:0.
     Asserted against the field's own edges: a magic offset here would drift the moment the + changes size. */
  const sAlign = await J(() => { const f = document.querySelector('.sfield').getBoundingClientRect(), g = document.querySelector('.sugg').getBoundingClientRect();
    return { dl: +(g.left - f.left).toFixed(1), dr: +(g.right - f.right).toFixed(1), clearsAdd: g.right <= document.querySelector('main .ibtn').getBoundingClientRect().left + 0.5 }; });
  ok(Math.abs(sAlign.dl) <= 1 && Math.abs(sAlign.dr) <= 1, `the dropdown tracks the field's own edges (${sAlign.dl} / ${sAlign.dr})`);
  ok(sAlign.clearsAdd, 'and stays clear of the + beside it');
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
  ok(await J(() => !!document.querySelector('#q') && document.querySelector('main h1').textContent === 'Juegos' && document.querySelector('.scroller').scrollTop === 0), 'the bar\'s back returns to Juegos at the top');

  /* ---------- decision 24 — BGG enrichment: pending and failed ----------
     The shipped admin DOES draw these (game_live/index.ex:242,363,372-380) — the handoff's "not drawn anywhere"
     was wrong. What it draws contradicts three rules settled since: an `alert alert-error` BOX inside a list row
     (D-19h says a status is a dot + text, never a pill, and an alert outweighs a pill), a Reintentar BUTTON in
     the row (D-19i reserves the trailing slot for "opens a page"; decision 2 sends picking a game to its
     editor), and it is the only surface for a state no query filters on — enrichment_status gates nothing, so a
     failed game is public the moment status is :published.
     ENR is a SCENARIO toggle, not a variant: the dev DB has zero pending and zero failed rows, so the resting
     page must stay the real 49 + 1 + 385, and these checks set the scenario explicitly. */
  const setEnr = async v => { await J(e => document.querySelector(`[data-enr-set="${e}"]`).click(), v); await p.waitForTimeout(120); };
  const openDraft = async () => { await J(() => { const h = [...document.querySelectorAll('.lhead.tap')].find(x => x.querySelector('.ln').textContent === 'Borradores');
    if (h && h.getAttribute('aria-expanded') !== 'true') h.click(); }); await p.waitForTimeout(160); };

  /* a failure is invisible at rest — this is WHY the caption has to carry it */
  await setEnr('failed');
  ok(await J(() => ![...document.querySelectorAll('.row')].some(r => r.querySelector('.dot'))),
    'a failed row is not even in the DOM while its section is closed');
  const warn = await J(() => { const w = document.querySelector('.lhead .warn'); if (!w) return null;
    const sc = document.querySelector('.scroller').getBoundingClientRect();
    const g = document.createRange(); g.selectNodeContents(w.closest('.lhead'));
    const r = g.getBoundingClientRect(); const first = document.querySelector('.lgroup.main .row').getBoundingClientRect();
    return { text: w.textContent.trim(), dot: !!w.querySelector('.dot.err'), inkH: +r.height.toFixed(1),
      inkRight: +r.right.toFixed(0), chrome: +(first.top - sc.top).toFixed(0),
      pill: !!w.querySelector('[class*=badge], [class*=alert], [class*=pill]'),
      bg: getComputedStyle(w).backgroundColor }; });
  ok(warn && warn.text === '1 con error' && warn.dot, `the closed caption reports it as a dot + text ("${warn && warn.text}")`);
  ok(warn && warn.bg === 'rgba(0, 0, 0, 0)' && !warn.pill, 'D-19h — a dot and text, never a pill, badge or alert box');
  ok(warn && near(warn.inkH, 19.5, 1.5), `the caption stays ONE line with it (${warn && warn.inkH}px of ink)`);
  ok(warn && warn.inkRight <= 300, `and leaves real slack at 360 (ink ends at x=${warn && warn.inkRight})`);
  /* "costs nothing" is a RELATIVE claim, so measure it relatively — a hardcoded 213 here turned decision 28's
     legitimate 4px saving into a false failure. Compare the page with the failure against the same page without. */
  await setEnr('');
  const bare = await J(() => { const sc = document.querySelector('.scroller').getBoundingClientRect();
    return +(document.querySelector('.lgroup.main .row').getBoundingClientRect().top - sc.top).toFixed(0); });
  await setEnr('failed');
  ok(warn && warn.chrome === bare, `it costs the resting page NOTHING (${warn && warn.chrome}px with the failure, ${bare} without)`);

  /* ONE anatomy still (decision 17/18): the warn is an optional affordance, like the caret — the ink that
     decides whether two headers are the same KIND of thing must stay byte-identical across all three. */
  const ana24 = await J(() => [...document.querySelectorAll('.lhead')].map(h => { const c = getComputedStyle(h), n = getComputedStyle(h.querySelector('.ln'));
    const g = document.createRange(); g.selectNodeContents(h.querySelector('.ln'));
    return [c.backgroundColor, parseFloat(n.fontSize) + '/' + n.fontWeight, n.color, +g.getBoundingClientRect().left.toFixed(0)].join('|'); }));
  ok(new Set(ana24).size === 1, `1 anatomy survives the failure report (${ana24[0]})`);

  /* the row itself, with the section open: the second line carries it — the slot the year already had */
  await openDraft();
  const r24 = await J(() => { const row = [...document.querySelectorAll('.row')].find(r => r.querySelector('.dot.err')); if (!row) return null;
    const L = e => { const g = document.createRange(); g.selectNodeContents(e); return +g.getBoundingClientRect().left.toFixed(0); };
    return { sub: row.querySelector('.sub').textContent.trim(), nameLeft: L(row.querySelector('.name')),
      subLeft: L(row.querySelector('.sub')), chev: !!row.querySelector('.chev'),
      buttons: row.querySelectorAll('button').length, act: row.dataset.act,
      warnGone: !document.querySelector('.lgroup .lhead .warn') || !!document.querySelector('.lhead[aria-expanded="true"] .warn') === false }; });
  ok(r24 && /^Error al traer datos de BGG$/.test(r24.sub), `the row says it on its SECOND line ("${r24 && r24.sub}")`);
  ok(r24 && r24.nameLeft === 68 && r24.subLeft === 68, `on the row's own keyline, adding no third text edge (${r24 && r24.nameLeft}/${r24 && r24.subLeft})`);
  ok(r24 && r24.chev && r24.buttons === 0 && r24.act === 'open',
    'the row keeps only its chevron — Reintentar belongs in the editor (D-19i + decision 2), not in a list row');
  ok(r24 && r24.warnGone, 'the caption drops the warning once the section is open — the rows say it themselves');

  /* pending: the state that arrives before the name does */
  await setEnr('pending'); await openDraft();
  const pnd = await J(() => { const row = [...document.querySelectorAll('.row')].find(r => r.querySelector('.dot')); if (!row) return null;
    return { name: row.querySelector('.name').textContent.trim(), sub: row.querySelector('.sub').textContent.trim(),
      skel: !!row.querySelector('.cov.skel'), err: !!row.querySelector('.dot.err'),
      h: +row.getBoundingClientRect().height.toFixed(0) }; });
  ok(pnd && /^Juego #\d+$/.test(pnd.name), `pending shows the placeholder name BGG has not replaced yet ("${pnd && pnd.name}")`);
  ok(pnd && pnd.sub === 'Trayendo datos de BGG…' && !pnd.err, `and an amber dot, not the danger one ("${pnd && pnd.sub}")`);
  ok(pnd && pnd.skel, 'its cover is a skeleton, the one part of the shipped design that was right');
  ok(pnd && pnd.h === 64, `and the row keeps the list's own height (${pnd && pnd.h})`);

  /* nothing anywhere reintroduces the shipped alert box */
  ok(await J(() => !document.querySelector('[class*=alert]')), 'no alert box anywhere on the page (D-19h)');
  await p.screenshot({ path: path.join(OUT, '11-enrichment-pending-375x740-light.png') });
  await setEnr('');
  ok(await J(() => !document.querySelector('.dot') && !document.querySelector('.lhead .warn')),
    'and with no pending or failed rows the page is byte-identical to the real data (49 + 1 + 385)');

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
      const first = document.querySelector('.lgroup.main .row').getBoundingClientRect();
      return { rest: rows.filter(r => { const b = r.getBoundingClientRect(); return b.top >= top - 1 && b.bottom <= tabs; }).length,
               oflow: scr.scrollWidth - scr.clientWidth,
               chrome: +(first.top - top).toFixed(0), pct: Math.round(100 * (first.top - top) / (tabs - top)) };
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
    /* decision 22's standing guard. The budget is a FIXED pixel count, so the worst ratio is the smallest
       phone — measure there, never on the roomiest one (which is how 51% got reported as 43%). */
    ok(m.pct <= 45, `${w}x${h}: chrome ${m.chrome}px = ${m.pct}% of usable, at or under the 45% ceiling`);
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
