/* Headless-Chrome checks for sketch 072 (the game editor). Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/072-admin-game-editor/verify.js
   Env: PLAYWRIGHT_CORE, SKETCH_URL, SHOTS_DIR (default <os tmp>/sketch-072-shots).
   Round 1 settled the spine (decision 33): every value is a row that opens a sheet. The losing variants
   (an inline form, a mixed spine) are removed; their measurements live in notes/juegos-ui-redesign.md. */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();
const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/072-admin-game-editor/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-072-shots'); fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);

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
  /* a click leaves the cursor on its target and :hover swaps the fill — park it before sampling colour */
  const cool = async () => { await p.mouse.move(-60, -60); await p.waitForTimeout(150); };
  const settle = async () => {
    await p.evaluate(() => [...document.querySelectorAll('img[loading="lazy"]')].forEach(i => i.loading = 'eager'));
    await p.waitForFunction(() => [...document.querySelectorAll('img.cov')].every(i => i.complete), null, { timeout: 8000 }).catch(() => {});
    await p.waitForTimeout(250);
  };
  await settle();

  /* ---------- the fields are exactly what the changeset casts ----------
     Game.admin_changeset/2 casts name, units, weight_band, is_expansion, description, shelf_id and nothing
     else. If the editor shows a seventh editable thing it is promising an edit the server will drop. */
  const CAST = ['name', 'units', 'weight_band', 'is_expansion', 'shelf_id', 'description'];
  {
    const v = 'spine';
    const keys = await J(() => {
      const out = new Set();
      for (const e of document.querySelectorAll('[data-edit]')) out.add(e.dataset.edit);
      for (const e of document.querySelectorAll('[data-f]')) out.add(e.dataset.f);
      if (document.querySelector('[data-step]')) out.add('units');
      return [...out];
    });
    ok(keys.length === CAST.length && CAST.every(k => keys.includes(k)),
      `${v}: exactly the 6 cast fields are editable (${keys.sort().join(', ')})`);
  }

  /* ---------- the spine, now single ----------
     The A/B/C comparison that produced decision 33 is gone with the losing variants; what survives is the
     property the winner was chosen FOR, asserted so it cannot drift back: one row anatomy. */
  {
    const m = await J(() => {
      const sc = document.querySelector('#scroller');
      const lab = [...document.querySelectorAll('.glabel')].find(l => l.textContent.includes('CLUB'));
      const bgg = [...document.querySelectorAll('.glabel')].find(l => l.textContent.includes('BGG'));
      const vis = sc.getBoundingClientRect(), tabs = document.querySelector('.tabs').getBoundingClientRect().top;
      const rows = [...document.querySelectorAll('.frow')];
      return {
        clubH: +(bgg.getBoundingClientRect().top - lab.getBoundingClientRect().top).toFixed(1),
        onScreen: rows.filter(u => { const r = u.getBoundingClientRect(); return r.top >= vis.top && r.bottom <= tabs; }).length,
        tags: [...new Set(rows.map(r => r.tagName))],
        trailing: [...new Set(rows.map(r => r.querySelector('.chev') ? 'chevron' : r.querySelector('.step') ? 'stepper' : r.querySelector('.sw') ? 'switch' : 'none'))],
        oflow: +(document.documentElement.scrollWidth - 375).toFixed(1)
      };
    });
    ok(m.oflow <= 0, `no horizontal overflow (${m.oflow}px)`);
    ok(m.tags.length === 1 && m.tags[0] === 'BUTTON', `ONE row anatomy: every row is the same element (${m.tags.join(', ')})`);
    ok(m.trailing.length === 1 && m.trailing[0] === 'chevron', `and the same trailing shape (${m.trailing.join(', ')}) — this is what A was chosen for`);
    ok(m.onScreen === 6, `all 6 club fields are on screen at rest (${m.onScreen})`);
    log.push(`INFO club block ${m.clubH}px · ${m.onScreen} fields at rest`);
    await p.screenshot({ path: path.join(OUT, '01-spine-375x740.png') });
  }

  /* ---------- the cost of the spine, counted as real clicks ----------
     The sheet round-trip is what A pays for one anatomy and six-of-six on screen. Counted, not reasoned
     about, so a future change that quietly adds a third tap shows up here. */
  {
    await J(() => document.querySelector('[data-edit="weight_band"]').click());
    await p.waitForTimeout(280);
    ok(await J(() => !!document.querySelector('[data-pick="weight_band"]')), 'tapping Nivel opens its picker sheet');
    await J(() => document.querySelectorAll('[data-pick="weight_band"]')[2].click());
    await p.waitForTimeout(280);
    ok(await J(() => document.querySelector('#savebar').classList.contains('on')), 'and choosing a level marks the page dirty');
    ok(await J(() => !document.querySelector('#sheet').classList.contains('open')), 'the sheet closes on the pick — no second confirm');
    const shown = await J(() => [...document.querySelectorAll('.frow')].find(r => r.querySelector('.fr-k').textContent === 'Nivel').querySelector('.fr-v').textContent);
    ok(shown === 'Intermedio', `the row now shows the chosen value (${shown}) — 2 taps, start to finish`);
    log.push('INFO one edit = 2 taps (open the sheet, pick) — the price of one anatomy');
  }

  /* ---------- the head is a mirror, not a second editable ----------
     The head shows the game's name and so does the Nombre row. They must be the SAME value: an editor that
     renames the page but not the row (or the reverse) is showing two answers to one question. */
  {
    await J(() => document.querySelector('[data-edit="name"]').click());
    await p.waitForTimeout(300);
    await J(() => { const i = document.querySelector('#s-name'); i.value = 'Brass: Lancashire'; });
    await J(() => document.querySelector('[data-commit="name"]').click());
    await p.waitForTimeout(280);
    const both = await J(() => ({
      head: document.querySelector('#ghname').textContent,
      row: [...document.querySelectorAll('.frow')].find(r => r.querySelector('.fr-k').textContent === 'Nombre').querySelector('.fr-v').textContent,
      bar: document.querySelector('#pbt').textContent
    }));
    ok(both.head === 'Brass: Lancashire' && both.row === both.head && both.bar === both.head,
      `the head, the row and the pinned bar all carry one name (${both.head} / ${both.row} / ${both.bar})`);
    /* put it back so later checks see the fixture's real game */
    await J(() => document.querySelector('#discard').click());
    await p.waitForTimeout(220);
  }

  /* ---------- D-19o, the press state settled in 071 decision 32 ----------
     Carried into this sketch from the start rather than retrofitted: the platform flash is suppressed at the
     root and every hoverable surface has an :active. */
  ok(await J(() => getComputedStyle(document.documentElement).webkitTapHighlightColor === 'rgba(0, 0, 0, 0)'),
    'the platform tap highlight is suppressed at the root (D-19o)');
  const rules = await J(() => {
    const hov = new Set(), act = new Set();
    const strip = x => x.replace(/:{1,2}(hover|active|before|after|focus-visible)/g, '').trim();
    const walk = rs => { for (let i = 0; i < rs.length; i++) { const r = rs[i];
      if (r.selectorText) { for (const s of r.selectorText.split(',')) {
        if (/:hover/.test(s)) hov.add(strip(s)); if (/:active/.test(s)) act.add(strip(s)); } }
      else if (r.cssRules) walk(r.cssRules); } };
    for (let i = 0; i < document.styleSheets.length; i++) { try { walk(document.styleSheets[i].cssRules); } catch (e) {} }
    return { hov: [...hov], act: [...act] };
  });
  /* #tools is the sketch's own toolbar, not the design under test — it is styled independently on purpose
     (sketch-tooling.md). Named EXPLICITLY rather than loosening the rule to a substring match, so a real
     control can never slip through by happening to contain the word. */
  const TOOLBAR = ['#tools', '#tools button'];
  const orphans = rules.hov.filter(h => !rules.act.includes(h) && !TOOLBAR.includes(h));
  ok(orphans.length === 0, `every hoverable surface has a press state (${orphans.length ? 'hover-only: ' + orphans.join(', ') : rules.hov.length + ' checked'})`);

  /* ---------- the form group label is 13/600, NOT the list caption's versalita ----------
     Decision 28's versalita 14/600 governs a LIST section header. This is a FORM group label, the
     BENCHMARK's `Label (group)` rank — conflating the two is what caused decision 20. */
  const lab = await J(() => { const l = document.querySelector('.glabel'); const c = getComputedStyle(l);
    return { size: c.fontSize, weight: c.fontWeight, transform: c.textTransform }; });
  ok(lab.size === '13px' && lab.weight === '600',
    `a form group label is 13/600, not the list caption's 14/600 versalita (${lab.size}/${lab.weight})`);

  /* ---------- key and value are two LINES, not two words on one ----------
     Found by looking at a screenshot while the whole harness was green: .fr-k/.fr-v are spans inside a
     button, so as inline boxes they ran together ("NombreBrass: Birmingham"). Height, contrast and hit-box
     checks all pass happily through that, because none of them asks where the ink SITS relative to its
     neighbour. Measured as ink, via Range rects, not as element boxes. */
  {
    const v = 'spine';
    const collide = await J(() => {
      const bad = [];
      for (const row of document.querySelectorAll('.frow')) {
        const k = row.querySelector('.fr-k'), val = row.querySelector('.fr-v');
        if (!k || !val) continue;
        const rr = e => { const g = document.createRange(); g.selectNodeContents(e); return g.getBoundingClientRect(); };
        const a = rr(k), b = rr(val);
        /* the value's ink must start BELOW the key's ink, not to its right */
        if (b.top < a.bottom - 1) bad.push(`${k.textContent}: value top ${b.top.toFixed(1)} vs key bottom ${a.bottom.toFixed(1)}`);
      }
      return bad;
    });
    ok(collide.length === 0, `${v}: every row's value sits BELOW its key, not beside it${collide.length ? ' — ' + collide.join('; ') : ''}`);
  }

  /* no single row may dominate the spine: a 4-line description had made its row 116px, nearly two rows. */
  const tallest = await J(() => {
    const rows = [...document.querySelectorAll('.frow')].map(r => ({ t: r.querySelector('.fr-k')?.textContent, h: +r.getBoundingClientRect().height.toFixed(1) }));
    return rows.sort((x, y) => y.h - x.h)[0];
  });
  ok(tallest.h <= 96, `no row dominates the list — tallest is ${tallest.t} at ${tallest.h}px (a summary row, not the whole value)`);

  /* ---------- D-19i: the row chevron is reserved for "opens a page" ----------
     "Rows that act in place (show an answer, open a sheet) have none." Every .frow here opens a SHEET, so
     none may carry the row chevron's glyph. Asserted on the PATH DATA, not on the icon's name or position:
     Juegos decision 26 found a caret that had been distinguished from the row chevron by position alone and
     was byte-identical to it. */
  const ROWCHEV = 'M9 5l7 7-7 7';
  {
    const v = 'spine';
    const bad = await J(rc => [...document.querySelectorAll('.frow')]
      .filter(r => [...r.querySelectorAll('path')].some(pp => pp.getAttribute('d') === rc))
      .map(r => r.querySelector('.fr-k')?.textContent), ROWCHEV);
    ok(bad.length === 0, `${v}: no sheet-opening row wears the page chevron (D-19i)${bad.length ? ' — ' + bad.join(', ') : ''}`);
    const drawn = await J(() => [...document.querySelectorAll('.frow .chev path')].map(pp => pp.getAttribute('d')));
    ok(drawn.length > 0 && drawn.every(d => d === 'M5 9l7 7 7-7'),
      `${v}: and each one draws the disclosure chevron-down (${new Set(drawn).size} glyph, ${drawn.length} rows)`);
  }

  /* ---------- the 44px touch floor ---------- */
  {
    const v = 'spine';
    /* HIT-TEST, do not read the box, and SCROLL — the first version of this check did neither.
       Reading getBoundingClientRect misses a control that reaches the floor through a pseudo-element hit box
       (the switch's track is 32px because that is what a switch looks like), and elementFromPoint can only
       answer for a point on screen — so a viewport-only sweep silently skipped every control below the fold
       and passed while the switch had no hit box at all. Negative-tested: removing `.sw::before` must turn
       this red. Probing 21px above and below the centre measures what a FINGER lands on. */
    const small = await J(async () => {
      const sc = document.querySelector('#scroller');
      const seen = new Map(); let tested = 0;
      const vw = window.innerWidth, vh = window.innerHeight;
      const sweep = () => {
        for (const e of document.querySelectorAll('button, input, select, textarea, [role=switch]')) {
          if (e.offsetParent === null || e.closest('#tools') || e.closest('.tabs')) continue;
          if (seen.has(e)) continue;
          const r = e.getBoundingClientRect();
          const cx = r.left + r.width / 2, cy = r.top + r.height / 2;
          if (cx < 0 || cx > vw || cy - 21 < 0 || cy + 21 > vh) continue;
          /* `hit.contains(e)` must NOT count: an ANCESTOR being hit means the finger landed outside the
             control, on the row around it. Including it made this assertion unfalsifiable — the switch's
             parent .frow-inline swallowed every probe and the guard stayed green with no hit box at all.
             A pseudo-element hit reports its ORIGINATING element, so `hit === e` already covers ::before. */
          const owns = y => { const hit = document.elementFromPoint(cx, y); return !!hit && (hit === e || e.contains(hit)); };
          if (!owns(cy)) continue;
          /* A probe point can be covered by a fixed OVERLAY — the save bar (which earlier checks switch on by
             dirtying the page), the tab bar, the page bar, a sheet. That is an obstruction, not a small
             target: recording it as a failure reported the 81px description row as under 44px. Skip this
             scroll position for this element and let a later one measure it unobstructed. */
          const OVERLAY = '.savebar, .tabs, .pbar, #sheet, .backdrop, .kbd-sim';
          const blocked = y => { const hit = document.elementFromPoint(cx, y); return !!hit && !!hit.closest(OVERLAY); };
          if (blocked(cy - 21) || blocked(cy + 21)) continue;
          tested++;
          seen.set(e, owns(cy - 21) && owns(cy + 21));
        }
      };
      const step = Math.floor(vh * 0.6);
      for (let y = 0; y <= sc.scrollHeight; y += step) {
        sc.scrollTop = y;
        await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)));
        sweep();
      }
      sc.scrollTop = 0;
      await new Promise(r => requestAnimationFrame(r));
      const out = [];
      for (const [e, okFlag] of seen) if (!okFlag) out.push({ t: (e.textContent || e.tagName).trim().slice(0, 22), h: +e.getBoundingClientRect().height.toFixed(1) });
      return { out, tested };
    });
    /* a skipping guard can pass by testing NOTHING — assert it actually reached every control the variant has. */
    /* Counted over #main only. The page bar, save bar, sheet and simulated keyboard are overlays that are
       deliberately off-screen or transparent at rest, so they are not hit-testable and counting them made
       this assertion unsatisfiable rather than strict. They get their own checks elsewhere. */
    const declared = await J(() => [...document.querySelectorAll('#main button, #main input, #main select, #main textarea, #main [role=switch]')]
      .filter(e => e.offsetParent !== null).length);
    ok(small.tested >= declared, `${v}: the touch-floor sweep reached every control (${small.tested}/${declared})`);
    ok(small.out.length === 0, `${v}: every control's HIT BOX clears the 44px touch floor${small.out.length ? ' — ' + small.out.map(s => s.t + ' box ' + s.h).join('; ') : ''} (${small.tested} tested)`);
  }

  /* ---------- the sheet clears the simulated keyboard (292px, the toolkit's number) ---------- */
  await J(() => document.querySelector('[data-edit="name"]').click());
  await p.waitForTimeout(400);
  const kb = await J(() => {
    const sh = document.querySelector('#sheet').getBoundingClientRect();
    const k = document.querySelector('.kbd-sim');
    return { kbdOpen: document.querySelector('#device').classList.contains('kbd'),
      sheetBottom: +sh.bottom.toFixed(1), kbdTop: k ? +k.getBoundingClientRect().top.toFixed(1) : null,
      commitVisible: !!document.querySelector('[data-commit]') };
  });
  ok(kb.kbdOpen && kb.commitVisible, `the name sheet opens the keyboard and still shows its Guardar (${kb.kbdOpen}/${kb.commitVisible})`);
  await p.screenshot({ path: path.join(OUT, '02-name-sheet-keyboard.png') });

  /* ---------- the D-19n page bar is an overlay: at rest it must cost ZERO layout ---------- */
  await p.goto(URL); await p.evaluate(() => { document.getElementById('tools').style.display = 'none'; });
  await settle();
  const restTop = await J(() => document.querySelector('.ghead').getBoundingClientRect().top);
  await J(() => { const s = document.querySelector('#scroller'); s.scrollTop = 260; });
  await p.waitForTimeout(280);
  const barOn = await J(() => ({ on: document.querySelector('#pbar').classList.contains('on'),
    focusables: [...document.querySelectorAll('#pbar .pb-back, #back')].filter(e => !e.closest('[inert]') && !e.hasAttribute('inert')).length,
    title: document.querySelector('#pbt').textContent }));
  ok(barOn.on, 'the page bar pins once the game head scrolls off (D-19n)');
  ok(barOn.focusables === 1, `exactly one back control is focusable while pinned (${barOn.focusables})`);
  ok(barOn.title === 'Brass: Birmingham', `the pinned bar carries the game's name (${barOn.title})`);
  await p.screenshot({ path: path.join(OUT, '03-pinned-bar.png') });
  await J(() => { const s = document.querySelector('#scroller'); s.scrollTop = 0; });
  await p.waitForTimeout(280);
  const restTop2 = await J(() => document.querySelector('.ghead').getBoundingClientRect().top);
  ok(Math.abs(restTop - restTop2) < 0.6, `the bar costs zero layout at rest (${restTop} -> ${restTop2})`);

  /* ---------- dark ---------- */
  await J(() => document.querySelector('[data-theme-set="dark"]').click());
  await p.waitForTimeout(250); await settle(); await cool();
  await p.screenshot({ path: path.join(OUT, '04-spine-a-dark.png') });
  await J(() => document.querySelector('[data-theme-set="light"]').click());

  /* ---------- contrast, on the ranks this sketch introduces ---------- */ await cool();
  const cr = await J(() => {
    const lum = c => { const [r, g, b] = c.match(/[\d.]+/g).slice(0, 3).map(Number).map(v => { v /= 255; return v <= .03928 ? v / 12.92 : Math.pow((v + .055) / 1.055, 2.4); }); return .2126 * r + .7152 * g + .0722 * b; };
    const bg = getComputedStyle(document.body).backgroundColor;
    const page = getComputedStyle(document.querySelector('.device')).backgroundColor;
    const ratio = (a, b) => { const l1 = lum(a), l2 = lum(b); return +((Math.max(l1, l2) + .05) / (Math.min(l1, l2) + .05)).toFixed(2); };
    const of = s => { const e = document.querySelector(s); return e ? ratio(getComputedStyle(e).color, page) : null; };
    return { value: of('.fr-v'), key: of('.fr-k'), label: of('.glabel'), fact: of('.kv dd') };
  });
  log.push(`INFO contrast — value ${cr.value} · key ${cr.key} · group label ${cr.label} · BGG fact ${cr.fact}`);
  for (const [k, v] of Object.entries(cr)) ok(v >= 4.5, `${k} clears 4.5:1 (${v})`);

  /* ---------- smaller phones ---------- */
  for (const [w, h] of [[360, 640], [390, 844]]) {
    const c2 = await browser.newContext({ viewport: { width: w, height: h }, deviceScaleFactor: 2 });
    const q = await c2.newPage();
    await q.goto(URL); await q.evaluate(() => { document.getElementById('tools').style.display = 'none'; });
    await q.waitForTimeout(400);
    const of2 = await q.evaluate(() => +(document.documentElement.scrollWidth - window.innerWidth).toFixed(1));
    ok(of2 <= 0, `${w}x${h}: no horizontal overflow (${of2}px)`);
    await q.screenshot({ path: path.join(OUT, `05-spine-a-${w}x${h}.png`) });
    await c2.close();
  }

  await browser.close();
  ok(errs.length === 0, `no page errors (${errs.length ? errs.join(' | ') : 'none'})`);
  console.log(log.join('\n'));
  const pass = log.filter(l => l.startsWith('PASS')).length, tot = log.filter(l => !l.startsWith('INFO')).length;
  console.log(`\n${pass}/${tot} passed · shots in ${OUT}`);
  process.exit(log.some(l => l.startsWith('FAIL')) ? 1 : 0);
})();
