/* Sketch 065 — the composed admin holds together as one app.
   Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/065-admin-composition/verify.js
   Walks Admin → Juegos → editor → ‹ Juegos → Web → sección → Estantes → Asignar → Perfil in light
   and dark at 375px, then desktop, asserting the drift rules this sketch landed on. */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();
const URL = (process.env.BASE || 'http://127.0.0.1:8765/.planning/sketches/') + '065-admin-composition/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-065-shots'); fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);

/* the walk: [name, page-side setup] */
const STOPS = [
  ['1-admin', "go('panel');"],
  ['2-juegos', "go('juegos');"],
  ['3-editor', "openEditor(J.games.find(g => g.bgg === 224517));"],
  ['4-back-juegos', "go('juegos');"],
  ['5-web', "go('secciones');"],
  ['6-seccion', "V.cur = 1; V.ed = null; V.memQ = ''; go('seccion');"],
  ['7-estantes', "go('estantes');"],
  ['8-asignar', "V.curShelf = 1; V.asgQ = ''; V.onShelfOpen = false; go('asignar');"],
  ['9-niveles', "go('niveles');"],
  ['10-staff', "go('staff');"],
];

/* ---- page-side measuring helpers, injected once ---- */
const PROBE = `
window.__m = () => {
  const dev = document.getElementById('device'), main = dev.querySelector('#main');
  const cs = el => getComputedStyle(el);
  const vis = el => { const r = el.getBoundingClientRect(); if (!r.width || !r.height) return false;
    for (let n = el; n && n !== document.body; n = n.parentElement) { const s = cs(n);
      if (s.visibility === 'hidden' || s.display === 'none' || +s.opacity === 0) return false;
      if (n.matches('.sheet:not(.open), .drawer:not(.open), [inert], [aria-hidden="true"]')) return false; } return true; };
  const mainTop = main.getBoundingClientRect().top;
  const back = main.querySelector('.back');
  /* the page's own title, whatever mechanism it uses */
  const title = main.querySelector('.ptitle, .title-in');
  /* the page HEAD is the back row + title (+ subtitle) (+ the spacer that closes it); the BODY is the
     first thing after it. Measuring "title bottom to the first .sec" was measuring past the subtitle
     and past Estantes' progress bar, which is a probe artefact, not drift. */
  const isHead = el => el.matches('.back, .eback-row, .ptitle, .trow, .thead, .psub, .banner.err')
    || (el.tagName === 'DIV' && !el.className && (el.getAttribute('style') || '').includes('height:'));
  const kids = [...main.children];
  const isSpacer = el => el.tagName === 'DIV' && !el.className && (el.getAttribute('style') || '').includes('height:');
  const lastHead = [...kids].reverse().find(el => isHead(el) && !isSpacer(el)) || null;
  const firstBody = kids.find((c, i) => !isHead(c) && kids.slice(0, i).every(isHead)) || null;
  const headHasSub = !!main.querySelector(':scope > .psub');
  const labels = [...main.querySelectorAll('.group-label, .sec-label, .flabel')].filter(vis).map(el => ({
    cls: el.className.trim().split(/\\s+/)[0], text: el.textContent.trim().slice(0, 28),
    size: cs(el).fontSize, weight: cs(el).fontWeight, transform: cs(el).textTransform, color: cs(el).color, tracking: cs(el).letterSpacing }));
  /* a row's rendered height grows when its name wraps (061, by design); what must be one value is the
     row's declared minimum and its leading slot. */
  const rows = [...main.querySelectorAll('.grow, .srow, .dlink')].filter(vis).map(el => ({
    cls: el.className.trim(), h: Math.round(el.getBoundingClientRect().height),
    min: (el.matches('.split') ? cs(el.querySelector('.gmain') || el) : cs(el)).minHeight,
    slot: (() => { const s = el.querySelector('.thumb, .slot40, .av40, .slot, .fslot'); return s ? Math.round(s.getBoundingClientRect().width) : null; })() }));
  const pri = [...main.querySelectorAll('.obtn, .b-pri')].filter(vis).map(el => ({
    text: el.textContent.trim(), top: Math.round(el.getBoundingClientRect().top - mainTop) }));
  const badges = [...dev.querySelectorAll('.tabs [data-tab]')].map(t => ({
    k: t.dataset.tab, badge: t.querySelector('.badge')?.textContent || '' }));
  const drawerCounts = [...dev.querySelectorAll('.drawer .dlink[data-nav]')].map(r => ({ k: r.dataset.nav, n: r.querySelector('.count')?.textContent || '' }));
  const tabs = dev.querySelector('.tabs').getBoundingClientRect(), devR = dev.getBoundingClientRect();
  return {
    screen: S.screen,
    scrollTop: dev.querySelector('.scroller').scrollTop,
    activeTab: [...dev.querySelectorAll('.tabs button.on')].map(b => b.dataset.tab),
    focusInMain: !!(document.activeElement && main.contains(document.activeElement)),
    backText: back ? back.textContent.trim() : null,
    backTop: back ? Math.round(back.getBoundingClientRect().top - mainTop) : null,
    titleText: title ? (title.value !== undefined ? title.value : title.textContent.trim()) : null,
    titleTop: title ? Math.round(title.getBoundingClientRect().top - mainTop) : null,
    titleSize: title ? cs(title).fontSize : null, titleWeight: title ? cs(title).fontWeight : null,
    titleFont: title ? cs(title).fontFamily.split(',')[0].replace(/"/g, '') : null,
    bodyTop: firstBody ? Math.round(firstBody.getBoundingClientRect().top - mainTop) : null,
    headHasSub,
    headToBody: (lastHead && firstBody) ? Math.round(firstBody.getBoundingClientRect().top - lastHead.getBoundingClientRect().bottom) : null,
    headEnd: lastHead ? Math.round(lastHead.getBoundingClientRect().bottom - mainTop) : null,
    labels, rows, pri, badges, drawerCounts,
    overflowX: dev.querySelector('.scroller').scrollWidth - dev.querySelector('.scroller').clientWidth,
    tabsVisible: tabs.top < devR.bottom - 4,
    tabsBottomGap: Math.round(devR.bottom - tabs.bottom),
  };
};
window.__kb = () => {
  const dev = document.getElementById('device');
  const sim = dev.querySelector('.kbdsim'); const sheet = dev.querySelector('.sheet.open');
  const devR = dev.getBoundingClientRect();
  const a = document.activeElement;
  return {
    kbd: dev.classList.contains('kbd'),
    kbTop: sim ? Math.round(sim.getBoundingClientRect().top) : null,
    tabsHidden: (() => { const t = dev.querySelector('.tabs').getBoundingClientRect(); return t.top >= devR.bottom - 4; })(),
    sheetBottom: sheet ? Math.round(sheet.getBoundingClientRect().bottom) : null,
    sheetTop: sheet ? Math.round(sheet.getBoundingClientRect().top) : null,
    devBottom: Math.round(devR.bottom),
    focusId: a ? a.id : null,
    focusBottom: a && dev.contains(a) ? Math.round(a.getBoundingClientRect().bottom) : null,
    focusFontSize: a && dev.contains(a) ? getComputedStyle(a).fontSize : null,
  };
};`;

(async () => {
  const b = await chromium.launch({ channel: 'chrome', headless: true });
  const p = await b.newPage({ viewport: { width: 420, height: 1100 } });
  const errs = []; p.on('pageerror', e => errs.push(e.message));
  await p.goto(URL); await p.evaluate(() => document.fonts.ready);
  await p.addScriptTag({ content: PROBE });

  /* ================= 1. the walk, phone, light ================= */
  const seen = [];
  for (const [name, setup] of STOPS) {
    await p.evaluate(s => { window.__err = null; try { (0, eval)(s); } catch (e) { window.__err = e.message; } }, setup);
    await p.waitForTimeout(260);
    const m = await p.evaluate(() => ({ ...window.__m(), err: window.__err }));
    seen.push([name, m]);
    ok(!m.err, `${name}: navigation ran ${m.err || ''}`);
    ok(m.overflowX <= 0, `${name}: no horizontal overflow (${m.overflowX}px)`);
    ok(m.scrollTop === 0, `${name}: opens at the top of the page (scrollTop ${m.scrollTop})`);
    ok(m.activeTab.length <= 1, `${name}: at most one tab is marked current (${m.activeTab.join(',') || 'none'})`);
    await (await p.$('#device')).screenshot({ path: `${OUT}/${name}-light.png` });
  }
  const by = n => seen.find(([k]) => k === n)[1];

  /* --- the active tab must follow the page, including into a drill-down --- */
  const tabOf = { '1-admin': 'panel', '2-juegos': 'juegos', '3-editor': 'juegos', '4-back-juegos': 'juegos',
    '5-web': 'secciones', '6-seccion': 'secciones', '7-estantes': 'estantes', '8-asignar': 'estantes' };
  for (const [n, want] of Object.entries(tabOf))
    ok(by(n).activeTab[0] === want, `${n}: the ${want} tab is the one lit (got ${by(n).activeTab[0] || 'none'})`);

  /* --- D1 page head: every drill-down uses the same back row, in the same place --- */
  const drill = ['3-editor', '6-seccion', '8-asignar'];
  const backs = drill.map(n => by(n));
  ok(backs.every(m => m.backText), `every drill-down has a back row (${drill.map((n, i) => n + ':' + (backs[i].backText || '—')).join(' ')})`);
  const backTops = [...new Set(backs.map(m => m.backTop))];
  ok(backTops.length === 1, `D1 back rows start at the same height on every drill-down (${backs.map((m, i) => drill[i] + ':' + m.backTop).join(' ')})`);

  /* --- D2 page title: one type for a page title across the admin --- */
  const titles = seen.filter(([n]) => n !== '3-editor').map(([n, m]) => [n, m.titleSize, m.titleWeight, m.titleFont]);
  const sig = [...new Set(titles.map(t => t.slice(1).join('/')))];
  ok(sig.length === 1, `D2 every page title is the same type (${titles.map(t => t[0] + ':' + t[1] + '/' + t[2] + ' ' + t[3]).join(' · ')})`);

  /* --- D3 vertical rhythm: the page head ends the same distance above the body, everywhere --- */
  const gaps = seen.map(([n, m]) => [n, m.headToBody]);
  const gapSet = [...new Set(gaps.map(g => g[1]))];
  ok(gapSet.length === 1, `D3 the page head ends the same distance above the body on every page (${gaps.map(g => g[0] + ':' + g[1]).join(' ')})`);
  /* and the title itself starts at the same height on every page with the same head shape */
  for (const withBack of [false, true]) {
    const grp = seen.filter(([, m]) => !!m.backText === withBack);
    if (grp.length < 2) continue;
    const tops = [...new Set(grp.map(([, m]) => m.titleTop))];
    ok(tops.length === 1, `D3 page titles start at the same height ${withBack ? 'under a back row' : 'with no back row'} (${grp.map(([n, m]) => n + ':' + m.titleTop).join(' ')})`);
  }

  /* --- D4 section labels: one label style for "a labelled block" --- */
  const styles = {};
  for (const [n, m] of seen) for (const l of m.labels) {
    const k = `${l.size}/${l.weight}/${l.transform}/${l.tracking}`;
    (styles[k] = styles[k] || []).push(`${n}:${l.cls}“${l.text}”`);
  }
  ok(Object.keys(styles).length === 1,
    `D4 one section-label style across the admin (${Object.entries(styles).map(([k, v]) => k + ' ← ' + v.slice(0, 3).join(', ')).join('  |  ')})`);

  /* --- D5 list rows: one row height + one slot size per row kind --- */
  const heights = {};
  for (const [n, m] of seen) for (const r of m.rows) {
    if (!r.cls.includes('grow') || r.cls.includes('niv')) continue;
    const k = `min ${r.min}/slot ${r.slot}`;
    (heights[k] = heights[k] || []).push(n);
  }
  ok(Object.keys(heights).length === 1, `D5 every list row declares the same minimum and slot (${Object.entries(heights).map(([k, v]) => k + ' ← ' + [...new Set(v)].join(',')).join(' | ')})`);

  /* --- D6 counters: the tab badge, the drawer count and the page agree, and keep agreeing --- */
  await p.evaluate(() => { go('estantes'); });
  await p.waitForTimeout(240);
  const before = await p.evaluate(() => ({ badge: document.querySelector('.tabs [data-tab="estantes"] .badge')?.textContent, page: unplacedN() }));
  ok(before.badge === String(before.page), `D6 Estantes badge matches the page before assigning (${before.badge} / ${before.page})`);
  await p.evaluate(() => { V.curShelf = 1; V.asgQ = ''; go('asignar'); });
  await p.waitForTimeout(240);
  await p.evaluate(() => { document.querySelector('[data-act="v-assign"]').click(); });
  await p.waitForTimeout(500);
  const after = await p.evaluate(() => ({ badge: document.querySelector('.tabs [data-tab="estantes"] .badge')?.textContent, page: unplacedN(), drawer: null }));
  ok(after.badge === String(after.page), `D6 Estantes badge follows an assignment (${after.badge} / ${after.page})`);
  ok(after.page === before.page - 1, `D6 assigning really moved one game (${before.page} → ${after.page})`);
  /* resolve every level mismatch; the badge and the Admin box must empty out with the page */
  await p.evaluate(() => { go('niveles'); });
  await p.waitForTimeout(240);
  for (let i = 0; i < 8; i++) {
    const n = await p.evaluate(() => { const b = document.querySelector('[data-act="v-niv-sheet"]'); if (!b) return 0; b.click(); return 1; });
    if (!n) break;
    await p.waitForTimeout(200);
    await p.evaluate(() => document.querySelector('[data-act="v-correct"]').click());
    await p.waitForTimeout(420);
  }
  const nivDone = await p.evaluate(() => ({
    left: V.mis.length,
    badge: document.querySelector('.tabs [data-tab="niveles"] .badge')?.textContent || '',
    drawer: [...document.querySelectorAll('.drawer .dlink[data-nav="niveles"] .count')].map(c => c.textContent).join(''),
    empty: !!document.querySelector('#main .empty'),
  }));
  ok(nivDone.left === 0 && nivDone.empty, `D6 every level mismatch can be resolved (${nivDone.left} left, empty state ${nivDone.empty})`);
  ok(nivDone.badge === '' && nivDone.drawer === '', `D6 the Revisar niveles badge and drawer count clear with the page (badge “${nivDone.badge}” drawer “${nivDone.drawer}”)`);
  const homeBox = await p.evaluate(() => { go('panel'); return null; });
  await p.waitForTimeout(260);
  const boxes = await p.evaluate(() => [...document.querySelectorAll('.box')].map(b => ({
    k: b.dataset.nav, num: b.querySelector('.box-num').textContent, foot: b.querySelector('.box-foot').textContent.trim() })));
  const niv = boxes.find(b => b.k === 'niveles'), est = boxes.find(b => b.k === 'estantes');
  ok(niv.num === '0' && /Todo coincide/.test(niv.foot), `D6 the Admin box for Revisar niveles agrees (${niv.num} · ${niv.foot})`);
  const liveUnplaced = await p.evaluate(() => unplacedN());
  ok(est.foot.replace(/\D/g, '') === String(liveUnplaced), `D6 the Admin box for Estantes agrees (${est.foot} vs ${liveUnplaced} sin ubicar)`);
  /* one ludoteca, one size: the Admin box and the Juegos page must count the same games */
  const sizes = await p.evaluate(() => { go('juegos'); return null; });
  await p.waitForTimeout(260);
  const jSum = await p.evaluate(() => document.querySelector('#main .jsum span').textContent.trim());
  const jBox = boxes.find(b => b.k === 'juegos');
  ok(jSum.replace(/\D/g, '') === jBox.num.replace(/\D/g, ''),
    `D6 the Admin box and the Juegos page count the same ludoteca (box ${jBox.num} · page “${jSum}”)`);
  await p.evaluate(() => { go('panel'); });
  await p.waitForTimeout(240);
  const staffBox = boxes.find(b => b.k === 'staff');
  const invites = await p.evaluate(() => V.staff.filter(x => x.st === 'pending').length);
  ok(staffBox.foot.replace(/\D/g, '') === String(invites) || (!invites && !/pendiente/.test(staffBox.foot)),
    `D6 the Admin box for Staff agrees (“${staffBox.foot}” vs ${invites} invitación pendiente)`);

  /* ================= 2. the mobile keyboard (059/061 flagged, never tested) ================= */
  await p.reload(); await p.waitForLoadState('load'); await p.evaluate(() => document.fonts.ready);
  await p.addScriptTag({ content: PROBE });

  /* K1 — a field under 16px zooms iOS in on focus; every admin field must be at least 16px on touch */
  const coarse = await b.newContext({ viewport: { width: 420, height: 1100 }, hasTouch: true, isMobile: true, deviceScaleFactor: 2 });
  const cp = await coarse.newPage();
  await cp.goto(URL); await cp.evaluate(() => document.fonts.ready);
  const fieldSizes = await cp.evaluate(() => {
    const out = [];
    const grab = () => [...document.querySelectorAll('#device input:not([type=checkbox]), #device textarea')]
      .filter(el => el.getBoundingClientRect().width).forEach(el => out.push({ where: S.screen, id: el.id || el.placeholder || el.type, size: getComputedStyle(el).fontSize }));
    for (const s of ['juegos', 'secciones', 'estantes', 'staff']) { go(s); grab(); }
    V.cur = 1; V.ed = null; go('seccion'); grab();
    V.curShelf = 1; go('asignar'); grab();
    openEditor(J.games.find(g => g.bgg === 224517)); E.descEdit = true; go('editar'); grab();
    return out;
  });
  const small = fieldSizes.filter(f => parseFloat(f.size) < 16);
  ok(small.length === 0, `K1 no admin field is under 16px on a touch pointer — iOS would zoom (${small.map(f => f.where + '/' + f.id + ' ' + f.size).join(', ') || 'none'})`);
  const metaTag = await cp.evaluate(() => document.querySelector('meta[name=viewport]').content);
  ok(!/maximum-scale|user-scalable\s*=\s*no/.test(metaTag), `K1 the zoom fix is not a pinch-zoom lockout (${metaTag})`);
  await coarse.close();

  /* K2 — the tab bar leaves while a field has focus */
  await p.evaluate(() => { go('juegos'); });
  await p.waitForTimeout(260);
  const kbOff = await p.evaluate(() => window.__kb());
  await p.evaluate(() => document.getElementById('add-in').focus());
  await p.waitForTimeout(320);
  const kbOn = await p.evaluate(() => window.__kb());
  ok(!kbOff.kbd && !kbOff.tabsHidden, 'K2 the tab bar is there with no keyboard');
  ok(kbOn.kbd && kbOn.tabsHidden, `K2 the tab bar leaves while a field has focus (kbd ${kbOn.kbd}, hidden ${kbOn.tabsHidden})`);
  await (await p.$('#device')).screenshot({ path: `${OUT}/kbd-juegos-add.png` });
  await p.evaluate(() => document.getElementById('add-in').blur());
  await p.waitForTimeout(320);
  const kbBack = await p.evaluate(() => window.__kb());
  ok(!kbBack.kbd && !kbBack.tabsHidden, 'K2 the tab bar comes back when the field loses focus');

  /* K3 — a bottom sheet with the keyboard open sits ON TOP of the keyboard, not under it */
  await p.evaluate(() => { V.curShelf = 1; V.asgQ = ''; go('asignar'); });
  await p.waitForTimeout(280);
  await p.evaluate(() => document.querySelector('[data-act="v-rename"]').click());
  await p.waitForTimeout(320);
  await p.evaluate(() => document.getElementById('ren-in').focus());
  await p.waitForTimeout(360);
  const k3 = await p.evaluate(() => window.__kb());
  ok(k3.kbd && k3.kbTop != null, `K3 the rename sheet opens the keyboard (kbd ${k3.kbd})`);
  ok(k3.sheetBottom != null && k3.sheetBottom <= k3.kbTop + 1, `K3 the sheet sits above the keyboard (sheet bottom ${k3.sheetBottom}, keyboard top ${k3.kbTop})`);
  ok(k3.focusBottom != null && k3.focusBottom <= k3.kbTop, `K3 the focused field is above the keyboard (field bottom ${k3.focusBottom}, keyboard top ${k3.kbTop})`);
  ok(k3.sheetTop >= 0, `K3 the sheet is not pushed off the top of the screen (top ${k3.sheetTop})`);
  await (await p.$('#device')).screenshot({ path: `${OUT}/kbd-sheet-rename.png` });
  await p.evaluate(() => closeAll());
  await p.waitForTimeout(300);

  /* K4 — editing the 063 title and description in place, with the keyboard up */
  for (const [what, open] of [['title', "document.getElementById('ed-name').focus();"],
                              ['desc', "document.querySelector('[data-act=\"e-desc-edit\"]').click();"]]) {
    await p.evaluate(() => { openEditor(J.games.find(g => g.bgg === 224517)); });
    await p.waitForTimeout(280);
    await p.evaluate(s => (0, eval)(s), open);
    await p.waitForTimeout(460);
    const k = await p.evaluate(() => window.__kb());
    ok(k.kbd, `K4 editing the ${what} in place opens the keyboard`);
    ok(k.focusBottom != null && k.focusBottom <= k.kbTop, `K4 the ${what} stays above the keyboard while you type (bottom ${k.focusBottom}, keyboard top ${k.kbTop})`);
    await (await p.$('#device')).screenshot({ path: `${OUT}/kbd-editor-${what}.png` });
    await p.evaluate(() => document.activeElement.blur());
    await p.waitForTimeout(280);
  }

  /* ================= 3. dark + desktop ================= */
  for (const theme of ['dark']) {
    await p.evaluate(t => document.documentElement.dataset.theme = t, theme);
    for (const [name, setup] of STOPS) {
      await p.evaluate(s => { try { (0, eval)(s); } catch (e) {} }, setup);
      await p.waitForTimeout(220);
      const m = await p.evaluate(() => window.__m());
      ok(m.overflowX <= 0, `${name} ${theme}: no horizontal overflow (${m.overflowX}px)`);
      await (await p.$('#device')).screenshot({ path: `${OUT}/${name}-${theme}.png` });
    }
    await p.evaluate(() => delete document.documentElement.dataset.theme);
  }
  const wide = await b.newPage({ viewport: { width: 1440, height: 1000 } });
  wide.on('pageerror', e => errs.push('desk: ' + e.message));
  await wide.goto(URL); await wide.evaluate(() => document.fonts.ready);
  await wide.addScriptTag({ content: PROBE });
  await wide.evaluate(() => { S.vp = 'desk'; render(); });
  await wide.waitForTimeout(300);
  for (const [name, setup] of STOPS) {
    await wide.evaluate(s => { try { (0, eval)(s); } catch (e) {} }, setup);
    await wide.waitForTimeout(220);
    const m = await wide.evaluate(() => window.__m());
    ok(m.overflowX <= 0, `${name} desk: no horizontal overflow (${m.overflowX}px)`);
    await (await wide.$('#device')).screenshot({ path: `${OUT}/${name}-desk.png` });
  }
  /* the tab bar must NOT hide on desktop: there is no soft keyboard there */
  await wide.evaluate(() => { go('juegos'); });
  await wide.waitForTimeout(280);
  await wide.evaluate(() => document.getElementById('add-in').focus());
  await wide.waitForTimeout(300);
  const deskKb = await wide.evaluate(() => window.__kb());
  ok(!deskKb.tabsHidden, `K2 the desktop tab row stays put when a field has focus (hidden ${deskKb.tabsHidden})`);
  await wide.close();

  ok(errs.length === 0, `no JS errors ${errs.slice(0, 4).join(' | ')}`);
  await p.close(); await b.close();
  console.log(log.join('\n'));
  const fails = log.filter(l => l.startsWith('FAIL')).length, passes = log.filter(l => l.startsWith('PASS')).length;
  console.log(`\n${passes}/${passes + fails} passed · screenshots in ${OUT}`);
  process.exitCode = fails ? 1 : 0;
})().catch(e => { console.log(log.join('\n')); console.error('CRASH', e.message); process.exit(1); });
