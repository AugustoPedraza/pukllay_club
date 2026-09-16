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
  /* weight census: the app ships Inter 400 and 600 only, so balance is about WHERE 600 lands.
     The rule the admin follows: 600 marks a label, an action, or a state that needs noticing;
     content is 400. Display type (Bebas) has one weight and is judged by size, not weight. */
  const runs = [];
  for (const el of main.querySelectorAll('*')) {
    if (!vis(el)) continue;
    const own = [...el.childNodes].filter(n => n.nodeType === 3 && n.textContent.trim()).map(n => n.textContent.trim()).join(' ');
    const val = (el.tagName === 'INPUT' || el.tagName === 'TEXTAREA') ? (el.value || el.placeholder || '') : '';
    const text = (own || val).trim(); if (!text) continue;
    const st = cs(el);
    runs.push({ sel: el.tagName.toLowerCase() + (typeof el.className === 'string' && el.className.trim() ? '.' + el.className.trim().split(/\s+/)[0] : ''),
      text: text.slice(0, 28), size: parseFloat(st.fontSize), w: +st.fontWeight,
      display: /Bebas/.test(st.fontFamily), isTitle: el.matches('.ptitle, .title-in') });
  }
  const boxes = [...main.querySelectorAll('.box')].map(bx => ({
    name: bx.querySelector('.name')?.textContent.trim(),
    bold: [...bx.querySelectorAll('*')].filter(el => vis(el) && +cs(el).fontWeight === 600
      && [...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim()) && !el.matches('.pend'))
      .map(el => (el.className || el.tagName) + '“' + el.textContent.trim().slice(0, 16) + '”'),
  }));
  /* every text field on a page is one control. The in-place editors 063 designed to look like the
     text they replace (title, description, the units number) are deliberately exempt — 064 exempts
     them from the stroke rule for the same reason. */
  const fields2 = [...main.querySelectorAll('.tin, .field input, .sfield input')]
    .filter(el => vis(el) && !el.matches('.desc-in, .num, .title-in')).map(el => {
      const c = cs(el);
      return { id: el.id || el.placeholder, h: Math.round(el.getBoundingClientRect().height),
        r: c.borderTopLeftRadius, bw: c.borderTopWidth, bg: c.backgroundColor };
    });
  /* Every block that holds a list names itself. Juegos was the only one that did not — its search,
     filters and 412 rows sat under no heading while Web labels "Filas del inicio", Estantes "Orden de
     recorrido", Staff "Equipo" and Asignar "Sin ubicar". */
  const listBlocks = [...main.querySelectorAll('section, .jsec, .grp')].filter(el => vis(el) && el.querySelector('.glist'))
    .filter(el => !el.parentElement.closest('section, .jsec, .grp'))
    .map(el => {
      const l = el.querySelector(':scope > .group-label, :scope > .sec-label, :scope > .lhead > .group-label, :scope > .lhead > .sec-label');
      /* a collapsible list names itself with its own disclosure row ("En este estante · 68 juegos"),
         which is both the header AND the control — a label above it would only repeat it. */
      const disc = el.querySelector(':scope > .glist > .disclose');
      return { has: !!(l && vis(l)) || !!(disc && vis(disc)),
        text: l ? l.textContent.trim().slice(0, 24) : disc ? disc.querySelector('.gname')?.textContent.trim().slice(0, 24) + ' ⌄' : null };
    });
  const err = main.querySelector('.err-t'), stt = main.querySelector('.st-pill.draft, .st-draft');
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
    labels, rows, pri, badges, drawerCounts, runs, boxes, fields2, listBlocks,
    errW: err ? +cs(err).fontWeight : null, stW: stt ? +cs(stt).fontWeight : null,
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

  /* --- D4 labels: two ranked tiers, one style each ---------------------------------------------
     A SECTION label names a block on the page; a FIELD label names one input inside it. Before the
     composition there were three styles doing these two jobs (11px caps muted, 12px sentence muted,
     13px sentence full colour) with no rank between them. Now: section 13px/600 in full colour,
     field one size step down and muted, so "Ajustes / Nombre / Subtítulo" reads as a heading with
     two fields under it rather than three near-identical lines. */
  const tier = l => ['group-label', 'sec-label'].includes(l.cls) ? 'section' : 'field';
  const styles = { section: {}, field: {} };
  for (const [n, m] of seen) for (const l of m.labels) {
    const k = `${l.size}/${l.weight}/${l.transform}`;
    const t = styles[tier(l)];
    (t[k] = t[k] || []).push(`${n}:${l.cls}“${l.text}”`);
  }
  for (const [name, set] of Object.entries(styles)) {
    if (!Object.keys(set).length) continue;
    ok(Object.keys(set).length === 1,
      `D4 one ${name}-label style across the admin (${Object.entries(set).map(([k, v]) => k + ' ← ' + v.slice(0, 3).join(', ')).join('  |  ')})`);
  }
  const secSize = parseFloat(Object.keys(styles.section)[0] || '0'), fldSize = parseFloat(Object.keys(styles.field)[0] || '0');
  ok(!fldSize || fldSize < secSize, `D4 a field label reads under a section label, not beside it (section ${secSize}px, field ${fldSize}px)`);

  /* --- D5 list rows: one row height + one slot size per row kind --- */
  const heights = {};
  for (const [n, m] of seen) for (const r of m.rows) {
    if (!r.cls.includes('grow') || r.cls.includes('niv')) continue;
    const k = `min ${r.min}/slot ${r.slot}`;
    (heights[k] = heights[k] || []).push(n);
  }
  ok(Object.keys(heights).length === 1, `D5 every list row declares the same minimum and slot (${Object.entries(heights).map(([k, v]) => k + ' ← ' + [...new Set(v)].join(',')).join(' | ')})`);

  /* --- W1 nothing in a page body outweighs the page's own title -----------------------------
     "412" used to be 22px/600, the same size AND weight as the title "Admin" above it, so the page
     had no lead. Display type (the editor's Bebas name and poster) is judged by size, not weight. */
  for (const [n, m] of seen) {
    const t = m.runs.find(r => r.isTitle); if (!t) continue;
    const over = m.runs.filter(r => !r.isTitle && !r.display && r.size >= t.size && r.w >= t.w)
      .map(r => `${r.sel}“${r.text}” ${r.size}/${r.w}`);
    ok(over.length === 0, `W1 ${n}: nothing outweighs the page title (${t.size}/${t.w}) ${over.slice(0, 3).join(', ')}`);
  }

  /* --- W2 a dashboard box has ONE bold thing: its name (the pending pill aside) --- */
  const adminBoxes = by('1-admin').boxes;
  ok(adminBoxes.length > 0, `W2 the Admin home renders its boxes (${adminBoxes.length})`);
  const fat = adminBoxes.filter(b => b.bold.length !== 1);
  ok(fat.length === 0, `W2 each Admin box has exactly one 600 run, its name (${fat.map(b => b.name + ': ' + b.bold.join(' ')).join(' | ') || 'ok'})`);

  /* --- W3 an error is not quieter than the status it stands in for --- */
  const jm = by('2-juegos');
  ok(jm.errW != null && jm.stW != null && jm.errW >= jm.stW,
    `W3 the BGG failure reads at least as loud as the Borrador pill (error ${jm.errW}, status ${jm.stW})`);

  /* --- W4 report the bold share per page, so a future round can see it move --- */
  for (const [n, m] of seen) {
    const b = m.runs.filter(r => r.w === 600).length;
    log.push(`     weight ${n}: ${b}/${m.runs.length} runs at 600 (${Math.round(b / m.runs.length * 100)}%)`);
  }

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

  /* --- L1 every block that holds a list names itself --- */
  for (const [n, m] of seen) {
    if (!m.listBlocks.length) continue;
    const bare = m.listBlocks.filter(b => !b.has);
    ok(bare.length === 0, `L1 ${n}: every list block has a visible label (${m.listBlocks.map(b => b.text || '«sin etiqueta»').join(' · ')})`);
  }
  ok(by('2-juegos').listBlocks.some(b => b.text === 'Juegos del club'),
    `L1 the Juegos list is named (${by('2-juegos').listBlocks.map(b => b.text).join(', ')})`);

  /* --- F1 one field anatomy ------------------------------------------------------------------
     Buscar and Agregar sit 24px apart, same size, same type. The search field used to be a filled
     pill (radius-full, --color-surface, transparent border) beside an outlined 8px field, so the two
     read as different species — and --color-surface is what a soft content BLOCK is made of in this
     admin, so it read as a container rather than an input. */
  const anat = {};
  for (const [n, m] of seen) for (const f of m.fields2) {
    const k = `${f.h}px/${f.r}/${f.bw}/${f.bg}`;
    (anat[k] = anat[k] || []).push(`${n}:${f.id}`);
  }
  ok(Object.keys(anat).length === 1,
    `F1 every text field is one control (${Object.entries(anat).map(([k, v]) => k + ' ← ' + v.slice(0, 3).join(', ')).join('  |  ')})`);
  const jf = by('2-juegos').fields2;
  ok(jf.length >= 2, `F1 the Juegos page has both the Agregar and the Buscar field (${jf.map(f => f.id).join(', ')})`);

  /* ================= S. status marks the exception (065 R2) =================
     407 of 412 games are published, so "Publicado" on every row was the least informative word on
     the page. Published is now the unmarked default; a draft and a retired game each carry a pill
     that says its word — never colour alone (WCAG 1.4.1) — and a retired row is muted, a draft row
     never is (grey means "unavailable"; a draft is the most actionable row there is). */
  for (const theme of ['light', 'dark']) {
    await p.evaluate(t => t === 'dark' ? document.documentElement.dataset.theme = 'dark' : delete document.documentElement.dataset.theme, theme);
    await p.evaluate(() => { J.prompt = null; J.add = ''; go('juegos'); });
    await p.waitForTimeout(320);
    const st = await p.evaluate(() => {
      const rgb = s => { const srgb = /^color\(srgb/.test(s); const m = s.replace(/^color\(srgb/, '').match(/[\d.]+/g).map(Number); const k = srgb ? 255 : 1; return { r: m[0] * k, g: m[1] * k, b: m[2] * k, a: srgb ? (/\//.test(s) ? m[3] : 1) : (m[3] ?? 1) }; };
      const lum = c => [c.r, c.g, c.b].map(v => { v /= 255; return v <= .03928 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4; }).reduce((s, v, i) => s + v * [.2126, .7152, .0722][i], 0);
      const cr = (x, y) => +((Math.max(lum(x), lum(y)) + .05) / (Math.min(lum(x), lum(y)) + .05)).toFixed(2);
      const bgOf = el => { const st = []; for (let n = el; n; n = n.parentElement) { const c = rgb(getComputedStyle(n).backgroundColor); if (c.a > 0) { st.push(c); if (c.a === 1) break; } } let base = { r: 255, g: 255, b: 255 }; for (const c of st.reverse()) base = { r: c.r * c.a + base.r * (1 - c.a), g: c.g * c.a + base.g * (1 - c.a), b: c.b * c.a + base.b * (1 - c.a) }; return base; };
      const rows = [...document.querySelectorAll('#jlist .glist .grow')].map(r => {
        const g = J.games.find(x => x.id === +r.dataset.gid) || {};
        const pill = r.querySelector('.st-pill');
        return { status: g.status, enr: g.enr, pill: pill ? pill.textContent.trim() : null,
          pillContrast: pill ? cr(rgb(getComputedStyle(pill).color), bgOf(pill)) : null,
          muted: r.classList.contains('is-retired'),
          nameColor: getComputedStyle(r.querySelector('.gname')).color,
          nameContrast: cr(rgb(getComputedStyle(r.querySelector('.gname')).color), bgOf(r)),
          sub: (r.querySelector('.gsub')?.textContent || '').replace(/\s+/g, ' ').trim() };
      });
      /* the banner compares one or two named games, so there every status shows */
      J.add = '13'; J.prompt = { bgg: 13, games: J.games.filter(x => x.bgg === 13 && x.enr === 'ok') }; refreshAdd();
      const banner = [...document.querySelectorAll('.banner .st-pill')].map(el => ({ text: el.textContent.trim(), contrast: cr(rgb(getComputedStyle(el).color), bgOf(el)) }));
      J.prompt = null; J.add = ''; refreshAdd();
      return { rows, banner };
    });
    const ok_ = st.rows.filter(r => r.enr === 'ok');
    /* S1 — published is unmarked; every exception is marked, and marked with a WORD */
    const wrongPub = ok_.filter(r => r.status === 'published' && r.pill);
    const wrongExc = ok_.filter(r => r.status !== 'published' && !r.pill);
    ok(wrongPub.length === 0, `S1 ${theme}: no published row carries a status marker (${wrongPub.length} do)`);
    ok(wrongExc.length === 0 && ok_.some(r => r.status !== 'published'), `S1 ${theme}: every draft/retired row is marked, with its word (${ok_.filter(r => r.pill).map(r => r.pill).join(', ') || 'none'})`);
    /* S2 — never colour alone, and the label clears 4.5:1 against what is really behind it */
    const faint = [...ok_.filter(r => r.pill), ...st.banner].filter(x => (x.pillContrast ?? x.contrast) < 4.5);
    ok(faint.length === 0, `S2 ${theme}: every status label ≥ 4.5:1 (${[...ok_.filter(r => r.pill).map(r => r.pill + ' ' + r.pillContrast), ...st.banner.map(x => x.text + ' ' + x.contrast)].join(' · ')})`);
    /* S3 — retired is muted, draft is never muted (grey means "unavailable") */
    const badMute = ok_.filter(r => r.muted !== (r.status === 'retired'));
    ok(badMute.length === 0, `S3 ${theme}: only retired rows are muted (${badMute.map(r => r.status).join(',') || 'ok'})`);
    const retired = ok_.find(r => r.status === 'retired'), draft = ok_.find(r => r.status === 'draft');
    ok(retired && draft && retired.nameColor !== draft.nameColor, `S3 ${theme}: a retired name reads differently from a draft name`);
    ok(!retired || retired.nameContrast >= 4.5, `S3 ${theme}: a muted retired name is still readable (${retired && retired.nameContrast}:1)`);
    /* S4 — the meta line keeps the year (it tells two editions apart) and drops the player count */
    const pub = ok_.find(r => r.status === 'published');
    ok(pub && /^\d{4}$/.test(pub.sub), `S4 ${theme}: a published row's meta line is just its year (“${pub && pub.sub}”)`);
    ok(!ok_.some(r => /jug\./.test(r.sub)), `S4 ${theme}: no row still shows a player count`);
    /* the banner states every status, including Publicado — it compares named games, it does not scan */
    ok(st.banner.length === 2 && st.banner.some(x => x.text === 'Publicado'),
      `S1 ${theme}: the edition banner states every status (${st.banner.map(x => x.text).join(', ')})`);
  }
  await p.evaluate(() => delete document.documentElement.dataset.theme);

  /* ================= R. alignment and rhythm (065 R6) =================
     Eight things the developer caught by eye; each is measured here so it cannot come back. */
  await p.evaluate(() => { openEditor(J.games.find(g => g.bgg === 224517)); });
  await p.waitForTimeout(400);
  await p.evaluate(() => { E.bggOpen = true; patch(); });
  await p.waitForTimeout(300);
  const R = await p.evaluate(() => {
    const rr = e => e.getBoundingClientRect(), cs = e => getComputedStyle(e);
    const main = document.querySelector('#main');
    /* the row content edge every end-of-row control lands on */
    const edge = (() => { const r = document.querySelector('.club6 .sbox .srow'); return +(rr(r).right - parseFloat(cs(r).paddingRight)).toFixed(1); })();
    const pens = [...main.querySelectorAll('.pen')].map(e => ({ cls: e.className.replace('pen ', '').trim(), right: +rr(e).right.toFixed(1) }));
    /* a section label's inline note must sit on the label's own baseline */
    const lbl = main.querySelector('.bgg6s .sec-label'), note = lbl.querySelector('.sec-note');
    const baseOf = host => { const q = document.createElement('span'); q.textContent = 'x';
      q.style.cssText = 'display:inline-block;width:0;overflow:hidden'; host.appendChild(q);
      const v = rr(q).bottom; q.remove(); return v; };
    const lblBase = (() => { const q = document.createElement('span'); q.textContent = 'x';
      q.style.cssText = 'display:inline-block;width:0;overflow:hidden'; lbl.insertBefore(q, lbl.firstChild);
      const v = rr(q).bottom; q.remove(); return v; })();
    const noteBase = baseOf(note);
    /* the control that collapses a box must be separated from the content it collapses */
    const body = main.querySelector('.bgg-body'), more = main.querySelector('.bgg-more');
    const moreGap = +(rr(more).top - (rr(body).bottom - parseFloat(cs(body).paddingBottom))).toFixed(1);
    /* the segmented control's cells */
    const seg = [...main.querySelector('.useg').children].map(k => +rr(k).width.toFixed(1));
    const copiesLabel = main.querySelector('#u-lbl').textContent.trim();
    /* Estado */
    const ebar = main.querySelector('.ebar.inline'), bst = ebar.querySelector('.bst'), acts = ebar.querySelector('.eactions');
    const last = [...acts.querySelectorAll('button')].pop();
    const outlined = last.matches('.obtn, .b-pri, .b-sec');
    return { edge, pens, baselineDelta: +(noteBase - lblBase).toFixed(1), moreGap, seg, copiesLabel,
      estado: { labelRight: +(rr(last).right - (outlined ? 0 : 12)).toFixed(1),
        contentEdge: +(rr(ebar).right - parseFloat(cs(ebar).paddingRight)).toFixed(1),
        top: +(rr(acts).top + (outlined ? 0 : 14) - rr(bst).bottom).toFixed(1),
        bottom: +(rr(ebar).bottom - (rr(acts).bottom - (outlined ? 0 : 14))).toFixed(1) } };
  });
  /* R1 — a pencil is either ON the row content edge or clearly away from it (following its own text).
     The Nivel pencil used to sit 7.7px inside the line, close enough to read as a miss. */
  const nearMiss = R.pens.filter(x => x.right < R.edge - 0.5 && x.right > R.edge - 24);
  ok(nearMiss.length === 0, `R1 no pencil almost-but-not-quite hits the ${R.edge}px row edge (${R.pens.map(x => x.cls + ':' + x.right).join(' ')})`);
  ok(R.pens.some(x => Math.abs(x.right - R.edge) <= 0.5), 'R1 the end-of-row pencils do sit on that edge');
  /* R2 — "Solo lectura" on the label's baseline, not floating above it */
  ok(Math.abs(R.baselineDelta) <= 2, `R2 the lock note sits on the section label's baseline (off by ${R.baselineDelta}px)`);
  /* R3 — the collapse control is separated from what it collapses */
  ok(R.moreGap >= 8, `R3 "Ver más" is split off from the content it collapses (${R.moreGap}px above it)`);
  /* R4 — equal cells, and the club's word */
  ok(new Set(R.seg).size === 1, `R4 the Copias cells are one width (${R.seg.join(' / ')})`);
  ok(R.copiesLabel === 'Copias', `R4 the label reads Copias, not Unidades (“${R.copiesLabel}”)`);
  /* R5 — Estado: the action's label lands on the content edge, and the box breathes evenly */
  ok(Math.abs(R.estado.labelRight - R.estado.contentEdge) <= 0.5,
    `R5 Estado's action label lands on the box content edge (${R.estado.labelRight} vs ${R.estado.contentEdge})`);
  ok(Math.abs(R.estado.top - R.estado.bottom) <= 2,
    `R5 Estado breathes evenly above and below its action (${R.estado.top} / ${R.estado.bottom})`);

  /* --- R6 every bottom sheet is built the same way --- */
  const SHEETS = {
    perfil: "go('panel'); setTimeout(()=>openEl('#sheet-account',document.querySelector('[data-act=open-account]')),150);",
    nivel: "openEditor(J.games.find(g=>g.bgg===224517)); setTimeout(()=>document.querySelector('[data-act=\"e-band-sheet\"]').click(),250);",
    estante: "openEditor(J.games.find(g=>g.bgg===224517)); setTimeout(()=>document.querySelector('[data-act=\"e-shelf-sheet\"]').click(),250);",
    filas: "openEditor(J.games.find(g=>g.bgg===224517)); setTimeout(()=>document.querySelector('[data-act=\"e-secs-sheet\"]').click(),250);",
    miembro: "V.cur=1;V.ed=null;go('seccion'); setTimeout(()=>document.querySelector('[data-act=\"v-mem-sheet\"]').click(),320);",
    nivelar: "Object.assign(V, seed062(true)); " + "go('niveles'); setTimeout(()=>document.querySelector('[data-act=\"v-niv-sheet\"]').click(),320);",
  };
  const shell = {};
  for (const [name, setup] of Object.entries(SHEETS)) {
    await p.evaluate(() => closeAll());
    await p.evaluate(x => { try { (0, eval)(x); } catch (e) {} }, setup);
    await p.waitForTimeout(700);
    const sh = await p.evaluate(() => {
      const el = document.querySelector('.sheet.open'); if (!el) return null;
      const cs = e => getComputedStyle(e), rr = e => e.getBoundingClientRect();
      const step = el.querySelector('.step:not([aria-hidden="true"])') || el;
      const lbl = step.querySelector('.group-label');
      const first = [...step.children].find(c => c !== lbl && rr(c).height);
      const rows = [...step.querySelectorAll('.dlink, .srow')].filter(r => rr(r).height);
      return { pad: cs(el).padding, grab: cs(el.querySelector('.grab')).margin,
        label: lbl ? `${cs(lbl).fontSize}/${cs(lbl).fontWeight}/${cs(lbl).textTransform}` : null,
        labelGap: (lbl && first) ? Math.round(rr(first).top - rr(lbl).bottom) : null,
        minRow: [...new Set(rows.map(r => cs(r).minHeight))].sort().join(','),
        rowInset: Math.round(rr(rows[0]).left - rr(el).left),
        navRowsMissingChev: rows.filter(r => /Ver (el sitio|en la)/.test(r.textContent) && !r.querySelector('.chev')).map(r => r.textContent.trim().slice(0, 22)) };
    });
    ok(!!sh, `R6 ${name}: the sheet opens`);
    if (sh) shell[name] = sh;
  }
  for (const key of ['pad', 'grab', 'label', 'labelGap', 'minRow', 'rowInset']) {
    const vals = {};
    for (const [n, v] of Object.entries(shell)) (vals[String(v[key])] = vals[String(v[key])] || []).push(n);
    ok(Object.keys(vals).length === 1,
      `R6 every sheet shares one ${key} (${Object.entries(vals).map(([k, v]) => k + ' ← ' + v.join(',')).join('  |  ')})`);
  }
  const noChev = Object.entries(shell).filter(([, v]) => v.navRowsMissingChev.length);
  ok(noChev.length === 0, `R6 a sheet row that navigates away carries a chevron (${noChev.map(([n, v]) => n + ':' + v.navRowsMissingChev.join('')).join(' ') || 'ok'})`);
  await p.evaluate(() => closeAll());

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
