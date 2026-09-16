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
/* 065 R9: the phone number of arrow presses to the middle of a 162-box estante, so the desk run can
   be compared against it rather than against a constant typed twice. */
let X_PRESSES_PHONE = null;

/* the walk: [name, page-side setup] */
const STOPS = [
  ['1-admin', "go('panel');"],
  ['2-juegos', "go('juegos');"],
  ['3-editor', "openEditor(J.games.find(g => g.bgg === 224517));"],
  ['4-back-juegos', "go('juegos');"],
  ['5-web', "go('secciones');"],
  ['6-seccion', "V.cur = 1; V.ed = null; V.memQ = ''; go('seccion');"],
  ['7-estantes', "go('estantes');"],
  /* 065 R8: stop 8 was `Estantes › Asignar`, a drill-down that no longer exists. The stop is not
     deleted — it re-points at the surface that inherited the whole job: an EXPANDED estante, on the
     Estantes page itself. Every geometry rule the walk carries is therefore still measured on the
     surface where the work happens. */
  ['8-estante-abierto', "V.listaQ = ''; V.ordering = null; V.adding = null; resetGrps(); V.grpOpen.s1 = true; go('estantes');"],
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
/* ---- round 7: one component per job (the Ajustes panel, the save bar, the reorder toggle, the
   search refresh). Everything here is measured, in the theme the caller has set. ---- */
window.__r7 = async () => {
  const rr = e => e.getBoundingClientRect(), cs = e => getComputedStyle(e), wait = ms => new Promise(r => setTimeout(r, ms));
  const rgb = s => { const srgb = /^color\\(srgb/.test(s); const m = s.replace(/^color\\(srgb/, '').match(/[\\d.]+/g).map(Number); const k = srgb ? 255 : 1; return { r: m[0] * k, g: m[1] * k, b: m[2] * k, a: srgb ? (/\\//.test(s) ? m[3] : 1) : (m[3] ?? 1) }; };
  const lum = c => [c.r, c.g, c.b].map(v => { v /= 255; return v <= .03928 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4; }).reduce((s, v, i) => s + v * [.2126, .7152, .0722][i], 0);
  const cr = (x, y) => +((Math.max(lum(x), lum(y)) + .05) / (Math.min(lum(x), lum(y)) + .05)).toFixed(2);
  const bgOf = el => { const st = []; for (let n = el; n; n = n.parentElement) { const c = rgb(cs(n).backgroundColor); if (c.a > 0) { st.push(c); if (c.a === 1) break; } } let base = { r: 255, g: 255, b: 255 }; for (const c of st.reverse()) base = { r: c.r * c.a + base.r * (1 - c.a), g: c.g * c.a + base.g * (1 - c.a), b: c.b * c.a + base.b * (1 - c.a) }; return base; };
  const hex = c => 'rgb(' + [c.r, c.g, c.b].map(v => Math.round(v)).join(',') + ')';
  const px = n => +n.toFixed(1);
  const out = {};

  /* --- C1/C2: the Ajustes block --- */
  V.cur = 1; V.ed = null; V.memQ = ''; go('seccion'); await wait(340);
  const main = document.querySelector('#main');
  const sec = main.querySelector('.jsec[aria-label="Ajustes"]');
  const panel = sec.querySelector('.sgroup.apanel');
  const kids = [...panel.children];
  const lbl = sec.querySelector(':scope > .group-label');
  out.panel = {
    /* every control the section owns has to be inside the one block */
    strays: [...sec.querySelectorAll('.tin, .srow, .switch')].filter(el => !el.closest('.sgroup.apanel')).map(el => el.id || el.className),
    kids: kids.map(k => k.className + ':' + px(rr(k).height)),
    gaps: kids.slice(1).map((k, i) => px(rr(k).top - rr(kids[i]).bottom)),
    padTop: px(rr(kids[0]).top - rr(panel).top),
    padBottom: px(rr(panel).bottom - rr(kids[kids.length - 1]).bottom),
    /* a field label and its own input are ONE unit, so that gap is the half step, not the rhythm */
    labelGap: (() => { const l = panel.querySelector('.flabel'); return px(rr(l.nextElementSibling).top - rr(l).bottom); })(),
    labelToPanel: px(rr(panel).top - rr(lbl).bottom),
    fill: hex(bgOf(panel)), pageFill: hex(bgOf(main)),
    /* a field on a tinted panel still has to clear the 3:1 non-text floor 064 holds fields to */
    strokes: [...panel.querySelectorAll('.tin')].map(f => ({ id: f.id, bw: cs(f).borderTopWidth,
      vsPanel: cr(rgb(cs(f).borderTopColor), bgOf(f.parentElement)) })),
  };
  out.fieldBlocks = [...main.querySelectorAll('.tin, .sfield input')].map(f => ({
    id: f.id, inPanel: !!f.closest('.sgroup.apanel'), behind: hex(bgOf(f.parentElement)) }));

  /* --- C3: the save bar, clean and dirty, against the editor's --- */
  const barOf = el => !el ? null : {
    cls: [...el.classList].sort().join('.'), pad: cs(el).padding, gap: cs(el).rowGap, fill: hex(bgOf(el)),
    radius: cs(el).borderTopLeftRadius, bw: cs(el).borderTopWidth, dir: cs(el).flexDirection,
    bl1: (() => { const x = el.querySelector('.bl1'); return x ? cs(x).fontSize + '/' + cs(x).fontWeight : null; })(),
    dot: !!el.querySelector('.bl1 .dot'), text: (el.querySelector('.bl1') || el).textContent.trim(),
    acts: [...el.querySelectorAll('.eactions > button')].map(b => b.className + '“' + b.textContent.trim() + '”'),
    actH: [...new Set([...el.querySelectorAll('.eactions > button')].map(b => Math.round(rr(b).height)))],
    lastRight: (() => { const b = [...el.querySelectorAll('.eactions > button')].pop(); return b ? px(rr(b).right) : null; })(),
    contentEdge: px(rr(el).right - parseFloat(cs(el).paddingRight)),
    top: px(rr(el.querySelector('.bst')).top - rr(el).top),
    bottom: px(rr(el).bottom - rr(el.querySelector('.eactions') || el.querySelector('.bst')).bottom),
    seam: (() => { const prev = el.previousElementSibling; return prev ? px(rr(el).top - rr(prev).bottom) : null; })(),
  };
  out.secBarClean = barOf(main.querySelector('#sec-bar'));
  const nameIn = document.getElementById('ed-name'); nameIn.focus();
  nameIn.value += ' 2'; nameIn.dispatchEvent(new Event('input', { bubbles: true }));
  await wait(200);
  out.secBarDirty = barOf(document.querySelector('#sec-bar'));
  out.secBarKeptTheField = document.activeElement === nameIn && document.getElementById('ed-name') === nameIn;
  V.ed = null; patch(); await wait(150);

  /* --- C4: the reorder toggle, off and on, on every page that renders an lhead --- */
  out.toggles = {};
  for (const [name, code] of [['web', "go('secciones')"], ['estantes', "V.listaQ='';resetGrps();go('estantes')"], ['seccion', "V.cur=1;V.ed=null;go('seccion')"]]) {
    (0, eval)(code); await wait(320);
    const read = () => {
      const m = document.querySelector('#main');
      const lh = [...m.querySelectorAll('.lhead')].find(l => l.querySelector('[data-act="v-order"]'));
      const btn = lh.querySelector('[data-act="v-order"]'), lb = lh.querySelector('.group-label');
      const right = lh.querySelector('.gcount, .pend');
      return { text: btn.textContent.trim(), pressed: btn.getAttribute('aria-pressed'), cls: btn.className,
        bw: parseFloat(cs(btn).borderTopWidth) * (cs(btn).borderTopStyle === 'none' ? 0 : 1),
        borderVsBg: cr(rgb(cs(btn).borderTopColor), bgOf(btn)), border: cs(btn).borderTopColor,
        h: Math.round(rr(btn).height), rowH: px(rr(lh).height),
        right: px(rr(btn).right), edge: px(rr(m).right - parseFloat(cs(m).paddingRight)),
        mid: px(rr(btn).top + rr(btn).height / 2), lblMid: px(rr(lb).top + rr(lb).height / 2),
        rightMid: right ? px(rr(right).top + rr(right).height / 2) : null };
    };
    const off = read();
    document.querySelector('[data-act="v-order"]').click(); await wait(300);
    const on = read();
    document.querySelector('[data-act="v-order"]').click(); await wait(300);
    out.toggles[name] = { off, on, backTo: read().text };
  }
  /* every other lhead right slot (a count) still shares the row's middle with its label */
  out.countHeads = [];
  /* 065 R8: estantes-lista and asignar were two screens; the one page that replaced them carries an
     lhead with a count-less right slot, plus the Resultados head that a query swaps in. */
  for (const [name, code] of [['staff', "go('staff')"], ['estantes', "V.listaQ='';resetGrps();go('estantes')"], ['estantes-buscando', "V.listaQ='catan';go('estantes')"]]) {
    (0, eval)(code); await wait(300);
    for (const lh of document.querySelectorAll('#main .lhead')) {
      const lb = lh.querySelector('.group-label'), right = lh.querySelector('.gcount, .pend');
      if (!lb || !right) continue;
      out.countHeads.push({ where: name + ':' + lb.textContent.trim().slice(0, 14),
        delta: px((rr(right).top + rr(right).height / 2) - (rr(lb).top + rr(lb).height / 2)) });
    }
  }
  V.listaQ = ''; resetGrps();

  /* --- C3 (cont.): the editor's bar, dirty, is the same component --- */
  openEditor(J.games.find(g => g.bgg === 224517)); await wait(420);
  out.editorBarClean = barOf(document.querySelector('#main .ebar.inline'));
  document.getElementById('u-set1').click(); await wait(320);
  out.editorBarDirty = barOf(document.querySelector('#main .ebar.inline'));
  seed('published'); S.screen = 'panel'; render(); await wait(220);

  /* --- C3 (cont.): there is exactly ONE save-bar implementation left in the admin --- */
  out.barCensus = { second: [], bars: [] };
  for (const s of ['panel', 'juegos', 'secciones', 'seccion', 'estantes', 'niveles', 'staff', 'editar']) {
    if (s === 'seccion') { V.cur = 1; V.ed = null; }
    if (s === 'editar') { openEditor(J.games.find(g => g.bgg === 224517)); } else go(s);
    await wait(260);
    for (const el of document.querySelectorAll('#main .saverow, #main .dirty-note'))
      out.barCensus.second.push(s + ':' + el.className);
    /* the component's own identity — NOT its padding: R6's rhythm rule makes the padding depend on what
       the action row holds (an all-text row supplies its own bottom padding, so the box's goes to 0),
       which is the same rule in both places, not two implementations. */
    for (const el of document.querySelectorAll('#main .ebar'))
      out.barCensus.bars.push(s + ':' + [...el.classList].sort().join('.') + ':' + cs(el).position + ':' + hex(bgOf(el))
        + ':' + cs(el).borderTopLeftRadius + ':' + cs(el).borderTopWidth + ' (pad ' + cs(el).padding + ')');
  }
  seed('published'); S.screen = 'panel'; render(); await wait(200);

  /* --- C5: typing in a search never replaces the field --- */
  out.typing = {};
  for (const [name, setup, id, word] of [
    ['mem-q', "V.cur=1;V.ed=null;V.memQ='';go('seccion')", 'mem-q', 'catan'],
    /* 065 R8: two searches, not three — asg-q went with the Asignar screen and lista-q took over
       its job, so this rule keeps both of its remaining subjects and loses no coverage. */
    ['lista-q', "V.listaQ='';resetGrps();go('estantes')", 'lista-q', 'cat'],
  ]) {
    (0, eval)(setup); await wait(340);
    const f = document.getElementById(id); f.focus();
    const first = f, boxes = [], same = [], carets = [];
    for (const ch of word) {
      f.value += ch; f.setSelectionRange(f.value.length, f.value.length);
      f.dispatchEvent(new Event('input', { bubbles: true }));
      await wait(380);
      const now = document.getElementById(id);
      same.push(now === first);
      carets.push(now.selectionStart);
      boxes.push([px(rr(now).width), px(rr(now).height), px(rr(now).top), px(rr(now).left)].join('/'));
    }
    const now = document.getElementById(id);
    out.typing[name] = { sameNode: same.every(Boolean), boxes: [...new Set(boxes)], carets,
      value: now.value, focused: document.activeElement === now,
      region: QREG[id][0], regionThere: !!document.getElementById(QREG[id][0]),
      changed: (document.getElementById(QREG[id][0]) || { textContent: '' }).textContent.length };
  }
  V.memQ = V.listaQ = ''; resetGrps();
  return out;
};
/* ---- round 7b, re-based by round 8: the collapsed-estante list survived the restructure; the view
   control it shared a round with did not. The fixture is still re-seeded at 4 and at 12 shelves,
   because "it scales" is only an honest claim if it is measured past the four the sketch ships. ---- */
window.__r7b = async () => {
  const rr = e => e.getBoundingClientRect(), cs = e => getComputedStyle(e), wait = ms => new Promise(r => setTimeout(r, ms));
  const rgb = s => { const srgb = /^color\\(srgb/.test(s); const m = s.replace(/^color\\(srgb/, '').match(/[\\d.]+/g).map(Number); const k = srgb ? 255 : 1; return { r: m[0] * k, g: m[1] * k, b: m[2] * k, a: srgb ? (/\\//.test(s) ? m[3] : 1) : (m[3] ?? 1) }; };
  const lum = c => [c.r, c.g, c.b].map(v => { v /= 255; return v <= .03928 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4; }).reduce((s, v, i) => s + v * [.2126, .7152, .0722][i], 0);
  const cr = (x, y) => +((Math.max(lum(x), lum(y)) + .05) / (Math.min(lum(x), lum(y)) + .05)).toFixed(2);
  const bgOf = el => { const st = []; for (let n = el; n; n = n.parentElement) { const c = rgb(cs(n).backgroundColor); if (c.a > 0) { st.push(c); if (c.a === 1) break; } } let base = { r: 255, g: 255, b: 255 }; for (const c of st.reverse()) base = { r: c.r * c.a + base.r * (1 - c.a), g: c.g * c.a + base.g * (1 - c.a), b: c.b * c.a + base.b * (1 - c.a) }; return base; };
  const px = n => +n.toFixed(1);
  const out = {};
  const sc = () => document.querySelector('#device .scroller');
  const view = () => ({ h: sc().scrollHeight, screen: sc().clientHeight, screens: +(sc().scrollHeight / sc().clientHeight).toFixed(2) });
  /* a group's own rows are .grow.gdisc (a placed game, which discloses its neighbours) or the Sin
     ubicar row, which discloses nothing and asks for a shelf instead. Never .disclose — round 8 keeps
     that class for a row that names a BLOCK, which is what L1 leans on. */
  const groups = () => [...document.querySelectorAll('#main .grp')].map(g => {
    const d = g.querySelector(':scope > .glist > .disclose'), cap = g.querySelector('.more .cap');
    return { key: d ? d.dataset.grp : null, named: !!d,
      name: d ? d.querySelector('.gname').textContent.trim() : null,
      sub: d ? d.querySelector('.gsub').textContent.trim() : null,
      open: d ? d.getAttribute('aria-expanded') === 'true' : null,
      visible: d ? rr(d).height > 0 : false, hdrH: d ? px(rr(d).height) : 0, h: px(rr(g).height),
      rows: g.querySelectorAll(':scope > .glist > .grow.gdisc, :scope > .glist > .grow[data-act="v-place-sheet"]').length,
      /* 065 R10: an estante's contents are the rail's TILES now, not vertical rows \u2014 the developer
         promoted R9's B. "Sin ubicar" is the one group that still opens to rows, because it is a queue
         of work and not a shelf, so both carriers are counted and C6 asserts whichever the group has. */
      tiles: g.querySelectorAll('.etile').length, bands: g.querySelectorAll('.egap').length,
      zoneBar: g.querySelectorAll('.ezones').length, slots: g.querySelectorAll('.etile').length + [...g.querySelectorAll('.egap')].reduce((a, e) => a + +e.dataset.n, 0),
      more: cap ? cap.textContent.trim() : null, deadCap: !!g.querySelector('.lcap') };
  });
  const reseed = n => { Object.assign(V, seed062(true, n), { ed: null, ordering: null, memQ: '', listaQ: '' }); resetGrps(); };

  /* --- C6: the estante list, at 4 shelves and at 12 --- */
  out.grouped = {};
  for (const n of [4, 12]) {
    reseed(n); go('estantes'); await wait(420);
    const collapsed = { ...view(), groups: groups(),
      /* the ledger has to add up at every n, or an expanded estante is lying about its own count */
      sumShelf: V.shelves.reduce((a, s) => a + shelfCount(s), 0), placed: placedN(), unplaced: unplacedN(), total: TOTAL };
    /* open every group in turn: each one must reveal REAL rows */
    for (const k of collapsed.groups.map(g => g.key)) {
      const b = document.querySelector('[data-act="v-toggle-grp"][data-grp="' + k + '"]'); if (b) b.click();
      await wait(90);
    }
    await wait(180);
    const expanded = { ...view(), groups: groups() };
    /* search: round 7b filtered the groups and kept all 13 headings, because the heading was the only
       thing that could say which estante a hit was on. The ROW says it now, so a query answers in one
       row instead of thirteen headings — the rule keeps its job and changes its carrier. */
    resetGrps(); patch(); await wait(220);
    const f = document.getElementById('lista-q'); f.focus();
    f.value = 'catan'; f.dispatchEvent(new Event('input', { bubbles: true })); await wait(460);
    const rows = [...document.querySelectorAll('#main .glist > .grow')];
    const searched = { ...view(), headings: document.querySelectorAll('#main .grp .disclose').length,
      label: (document.querySelector('#main .lhead .group-label') || {}).textContent,
      count: (document.querySelector('#main .gcount') || {}).textContent,
      hits: rows.map(x => ({ name: x.querySelector('.gname').textContent.trim(), sub: x.querySelector('.gsub').textContent.trim(),
        top: Math.round(rr(x).top + sc().scrollTop - rr(sc()).top), h: Math.round(rr(x).height) })),
      fieldSurvived: document.getElementById('lista-q') === f };
    f.value = ''; f.dispatchEvent(new Event('input', { bubbles: true })); await wait(420);
    out.grouped[n] = { collapsed, expanded, searched };
  }
  reseed(4);

  /* --- C7: the chip row. Round 7b put the Estantes view switch on this component and round 8 retired
     the switch, so the rule loses its second instance and keeps its first: 061's four filter chips,
     which R7b's --stroke fix improved and which are still the admin's one "pick one of N". What is
     asserted about Estantes now is the opposite claim: it has NO view control at all. --- */
  const chipsOf = () => {
    const main = document.querySelector('#main'), page = bgOf(main);
    return [...main.querySelectorAll('.chip')].filter(k => rr(k).height).map(k => {
      const g = k.querySelector('svg');
      return { text: k.textContent.trim().replace(/\\s+/g, ' '), on: k.classList.contains('on'),
        radius: cs(k).borderTopLeftRadius, bw: parseFloat(cs(k).borderTopWidth) * (cs(k).borderTopStyle === 'none' ? 0 : 1),
        vsPage: cr(rgb(cs(k).borderTopColor), page), vsFill: cr(rgb(cs(k).borderTopColor), bgOf(k)),
        tick: !!g, tickVsFill: g ? cr(rgb(cs(k).color), bgOf(k)) : null,
        h: px(rr(k).height), hit: px(rr(k).height) + 12, fw: +cs(k).fontWeight, pressed: k.getAttribute('aria-pressed') };
    });
  };
  V.listaQ = ''; resetGrps(); go('estantes'); await wait(420);
  out.noSwitch = { title: document.querySelector('#main .ptitle').textContent.trim(),
    segs: document.querySelectorAll('#main .seg').length, chips: document.querySelectorAll('#main .chip').length,
    radios: document.querySelectorAll('#main [role="radiogroup"], #main [role="radio"]').length,
    vista: document.querySelectorAll('#main [data-act="v-vista"]').length,
    searches: document.querySelectorAll('#main input[type="search"]').length,
    shelves: document.querySelectorAll('#main .grp .disclose').length, ofShelves: V.shelves.length + 1 };
  /* the same component on Juegos, and every other shape in that control stack */
  J.prompt = null; J.add = ''; go('juegos'); await wait(420);
  out.filterChips = chipsOf();
  out.stack = [...document.querySelectorAll('#main .chip, #main .tin, #main .sfield input, #main .obtn')]
    .filter(e => rr(e).height).map(e => (e.id || e.className.trim().split(/\\s+/)[0]) + ':' + cs(e).borderTopLeftRadius);
  go('panel'); await wait(220);
  return out;
};
/* ---- round 8: ONE Estantes page. The zone, the neighbours, remove and sort inside an expanded
   estante, the retired screen's jobs, and the fixture that has to be real for any of it to mean
   anything. Everything here is driven, not inspected. ---- */
window.__r8 = async () => {
  const rr = e => e.getBoundingClientRect(), cs = e => getComputedStyle(e), wait = ms => new Promise(r => setTimeout(r, ms));
  const px = n => +n.toFixed(1);
  const sc = () => document.querySelector('#device .scroller');
  const main = () => document.querySelector('#main');
  const abs = e => Math.round(rr(e).top + sc().scrollTop - rr(sc()).top);
  const reset = (n = 4) => { Object.assign(V, seed062(true, n), { ed: null, ordering: null, memQ: '', listaQ: '' }); resetGrps(); };
  const gname = x => x.querySelector('.gname').textContent.trim();
  const grpOf = k => document.querySelector('[data-act="v-toggle-grp"][data-grp="' + k + '"]').closest('.grp');
  const rowsOf = k => [...grpOf(k).querySelectorAll(':scope > .glist > .grow.gdisc, :scope > .glist > .grow[data-act="v-place-sheet"]')];
  /* 065 R10: an estante's contents are the rail's tiles. Every P-rule below that used to walk vertical
     rows walks these instead — same rule, new carrier — and each re-pointing says so where it lands. */
  const tilesOf = k => [...grpOf(k).querySelectorAll('.etile')];
  const tname = t => (t.getAttribute('aria-label') || '').replace(/,\\s*caja \\d+ de \\d+$/, '');
  const markTile = async (k, nth) => { const t = tilesOf(k)[nth]; t.click(); await wait(420); return t; };
  const out = {};

  /* --- P1 one page, and the geometry of what leads it --- */
  reset(); go('estantes'); await wait(420);
  out.page = {
    h: sc().scrollHeight, screens: +(sc().scrollHeight / sc().clientHeight).toFixed(2),
    titleTop: abs(main().querySelector('.ptitle')), progTop: abs(main().querySelector('.prog')),
    searchTop: abs(main().querySelector('#lista-q')),
    label: main().querySelector('.lhead .group-label').textContent.trim(),
    firstShelfTop: abs(main().querySelector('.grp .disclose')),
    shelves: main().querySelectorAll('.grp .disclose').length,
    /* "Nuevo estante" is a page-level SECONDARY action, and it is out of the finding job's way */
    newShelf: (() => { const b = main().querySelector('[data-act="v-new-shelf"]'); return b ? { top: abs(b), cls: b.className.trim(),
      h: Math.round(rr(b).height), inBody: !!b.closest('.jsec'), pop: b.getAttribute('aria-haspopup'),
      form: main().querySelectorAll('#shelf-new-form').length } : null; })(),
    addForms: main().querySelectorAll('form').length,
    overflowX: sc().scrollWidth - sc().clientWidth,
  };

  /* --- P2/P5 an expanded estante: the shelf's real slots, in the shelf's own order -----------------
     065 R10 RE-POINTS BOTH RULES ONTO THE RAIL. P2 said "an open estante lists its games in the shelf's
     own order" and P5 said "inside an open estante the order IS the position, so no row restates it" —
     both are still exactly the claim, and both are read off tiles now: the tiles carry the shelf's order
     left to right, and the position is on the geometry plus each tile's accessible name, with no zone
     word rendered anywhere inside the estante. */
  document.querySelector('[data-act="v-toggle-grp"][data-grp="s2"]').click(); await wait(420);
  const order2 = ordOf(2).filter(x => x != null).map(x => gById(x).name);
  {
    const g = grpOf('s2'), wrap = g.querySelector('.erail-wrap'), rail = g.querySelector('.erail');
    const c = cs(wrap), pxv = k => parseFloat(c.getPropertyValue(k));
    out.open = {
      rows: rowsOf('s2').map(gname),
      tiles: tilesOf('s2').map(tname), tileSlots: tilesOf('s2').map(t => +t.dataset.slot), order: order2,
      labels: tilesOf('s2').map(t => t.getAttribute('aria-label')),
      /* a zone word anywhere inside an open estante would be R8's retired restatement coming back */
      zoneWords: [...g.querySelectorAll('.etile, .ecap, .gsub, .epanel, .gnote, .ename')].filter(e => /Más a la izquierda|Al medio|Más a la derecha/.test(e.textContent)).length,
      shelfName: shelfById(2).name,
      repeatsShelfName: tilesOf('s2').filter(t => tname(t).includes(shelfById(2).name)).length,
      cap: (g.querySelector('.more .cap') || {}).textContent,
      mores: g.querySelectorAll('.more').length,
      count: g.querySelector('.disclose .gsub').textContent.trim(),
      railGroupLabel: rail.getAttribute('aria-label'),
      acts: [...g.querySelectorAll('.gacts button')].map(b => ({
        act: b.dataset.act, label: b.textContent.trim() || b.getAttribute('aria-label'),
        h: Math.round(rr(b).height), cls: b.className.trim(),
        right: px(rr(b).right), edge: px(rr(main()).right - parseFloat(cs(main()).paddingRight)) })),
      pitch: pxv('--etile') + pxv('--egap'),
    };
  }
  /* WHAT A MARKED TILE OPENS — the panel that carries the row's two jobs, which is where P5's "the
     row's own actions are there, remove included" now lives. */
  {
    await markTile('s2', 0);
    const g = grpOf('s2'), pan = g.querySelector('.epanel'), on = g.querySelector('.etile.on');
    out.panel = { name: pan.querySelector('.ename').textContent.trim(), marked: on.getAttribute('aria-label'),
      pressed: on.getAttribute('aria-pressed'), h: Math.round(rr(pan).height),
      acts: [...pan.querySelectorAll('button')].map(b => b.dataset.act + '“' + b.textContent.trim() + '”'),
      /* one at a time: marking another tile un-marks this one */
      onlyOne: (() => { tilesOf('s2')[1].click(); return g.querySelectorAll('.etile.on').length; })() };
    await wait(400);
  }
  /* --- P5 (cont.) THE SEARCH-RESULT EXPANSION. R10 ships R9's B, so this is the rail scrolled to the
     answer and marked, and the collapsed row above it still carries “zona · estante” — the pairing R9
     measured and B had thrown away. The old assertion "the expansion starts on the row's own text
     column" is re-pointed and INVERTED, with its reason: a rail is full-bleed by definition (its fade
     sits on the page's own edges, like the catalogue's), so the expansion reaches back OUT to the page
     edge — the one place a -68px margin appears in this admin. */
  reset(); patch(); await wait(320);
  {
    const f0 = document.getElementById('lista-q'); f0.focus(); f0.value = 'dixit';
    f0.dispatchEvent(new Event('input', { bubbles: true })); await wait(500);
    const row = main().querySelector('.grow.gdisc');
    const collapsedSub = row.querySelector('.gsub').textContent.trim();
    const nameLeft = px(rr(row.querySelector('.gname')).left);
    row.click(); await wait(640);
    const reRow = main().querySelector('.grow.gdisc'), exp = main().querySelector('.gexp');
    const rail = exp.querySelector('.erail'), on = exp.querySelector('.etile.on');
    const r0 = rr(rail), vis2 = [...exp.querySelectorAll('.etile, .egap')].filter(e => { const r = rr(e); return r.right > r0.left + 2 && r.left < r0.right - 2; });
    const i2 = vis2.indexOf(on);
    out.exp = { collapsedSub, name: tname(on), marked: on.getAttribute('aria-label'),
      left: px(rr(exp.querySelector('.erail-wrap')).left), nameLeft,
      pageLeft: px(rr(main()).left), h: Math.round(rr(exp).height),
      aria: reRow.getAttribute('aria-expanded'),
      bar: exp.querySelectorAll('.ezones').length,
      neighbours: { left: i2, right: vis2.length - 1 - i2, names: vis2.map(e => (e.getAttribute('aria-label') || e.textContent).trim().slice(0, 22)) },
      centred: Math.abs((rr(on).left + rr(on).width / 2) - (r0.left + r0.width / 2)) < 24,
      acts: [...exp.querySelectorAll('.gxacts button')].map(b => b.dataset.act + '“' + b.textContent.trim() + '”'),
      onlyOne: (() => { const o = [...main().querySelectorAll('.grow.gdisc')]; if (o[1]) o[1].click(); return document.querySelectorAll('.gexp').length; })() };
    await wait(340);
    const f1 = document.getElementById('lista-q'); f1.value = ''; f1.dispatchEvent(new Event('input', { bubbles: true })); await wait(420);
  }

  /* --- P3 remove, and the ledger following. R10: from a MARKED TILE's panel instead of a row's
     expansion — same rule ("remove works from the surface that answers where it is, and every counter
     follows"), same undo, new carrier. */
  reset(); V.grpOpen.s2 = true; patch(); await wait(340);
  const before3 = { order: ordOf(2).slice(), count: shelfCount(shelfById(2)), unplaced: unplacedN(), placed: placedN(),
    sum: V.shelves.reduce((a, s) => a + shelfCount(s), 0) };
  const victim = await markTile('s2', 1); const vName = tname(victim);
  main().querySelector('.epanel [data-act="v-rm-shelf"]').click(); await wait(560);
  const after3 = { order: ordOf(2).slice(), count: shelfCount(shelfById(2)), unplaced: unplacedN(), placed: placedN(),
    sum: V.shelves.reduce((a, s) => a + shelfCount(s), 0), badge: (document.querySelector('.tabs [data-tab="estantes"] .badge') || {}).textContent || '',
    prog: main().querySelector('.prog-line').textContent.replace(/\\s+/g, ' ').trim(),
    snack: document.querySelector('#snack span').textContent.trim() };
  document.querySelector('#snack button').click(); await wait(420);
  const undone3 = { order: ordOf(2).slice(), count: shelfCount(shelfById(2)), unplaced: unplacedN(),
    sum: V.shelves.reduce((a, s) => a + shelfCount(s), 0) };
  out.remove = { name: vName, before: before3, after: after3, undone: undone3,
    sameOrder: JSON.stringify(before3.order) === JSON.stringify(undone3.order) };

  /* --- P4 sort, inside an expanded estante: the ORDER array moves, one slot at a time ---------------
     065 R10 RE-POINTS THE DRIVER AND KEEPS THE RULE, and this is the one place the promotion makes the
     page BETTER by R9's own accounting: R9 recorded that "← / → is physically honest where ↑ / ↓ is
     not — the rail's one clean victory", and left it as an open item because a vertical list's glyph
     and label pointed different ways. With the rail shipped the glyph and the label finally agree, so
     that item closes here. The arrows live in the marked tile's panel and the assertions below are the
     same ones: one slot at a time, it swaps with the slot that was there, disabled at the ARRAY's ends
     (not at the last NAMED box), the hint says the real box moves, and Listo is the admin's Principal. */
  reset(); V.grpOpen.s2 = true; V.ordering = 'sh2'; patch(); await wait(360);
  const named = ordOf(2).map((x, i) => [x, i]).filter(([x]) => x != null);
  const mid = named[2];                         /* an interior named game: both neighbours are named */
  const before4 = ordOf(2).slice();
  /* mark the tile whose box we are about to move, then press its own ← */
  { const t = grpOf('s2').querySelector('.etile[data-slot="' + mid[1] + '"]'); t.click(); await wait(420); }
  const g4 = grpOf('s2');
  const arrowsAre = [...g4.querySelectorAll('.epanel [data-act="v-move"]')].map(b => b.getAttribute('aria-label'));
  const left = g4.querySelector('.epanel [data-act="v-move"][data-dir="-1"]');
  left.click(); await wait(460);
  const after4 = ordOf(2).slice();
  out.sort = { tiles: tilesOf('s2').length, hint: (grpOf('s2').querySelector('.gnote') || {}).textContent.trim(),
    id: mid[0], movedName: gById(mid[0]).name, at: mid[1], movedTo: after4.indexOf(mid[0]),
    swappedWith: before4[mid[1] - 1], nowAt: after4[mid[1]],
    orderChanged: JSON.stringify(before4) !== JSON.stringify(after4),
    onlyTwoMoved: before4.filter((x, i) => x !== after4[i]).length === 2,
    /* the labels point the way the BOX moves, which is the whole of the rail's one clean victory */
    arrowLabels: arrowsAre,
    /* and the mark follows the box: the panel still names the game you moved, at its new slot */
    markFollowed: (() => { const on = grpOf('s2').querySelector('.etile.on'); const pan = grpOf('s2').querySelector('.epanel');
      return { slot: on ? +on.dataset.slot : null, name: pan ? pan.querySelector('.ename').textContent.trim() : null }; })(),
    /* an arrow is disabled at the ARRAY's ends, not at the first or last NAMED box — a box really can
       be pushed past a slot whose title this sketch does not render. The fixture puts each shelf's
       named run at a different offset (start / middle / end, cycling), so this walks all three cases:
       shelf 1's run starts at slot 0, shelf 3's ends at the last slot, and shelf 2's sits mid-shelf,
       where NO named box may have a disabled arrow. */
    ends: (() => { const out2 = [];
      for (const sid of [1, 2, 3]) {
        const a = ordOf(sid);
        V.ordering = 'sh' + sid; resetGrps(); V.ordering = 'sh' + sid; V.grpOpen['s' + sid] = true;
        for (const [id, i] of a.map((x, k) => [x, k]).filter(([x]) => x != null)) {
          V.tileOn = { sid, slot: i }; patch();
          const q = d => { const b = grpOf('s' + sid).querySelector('.epanel [data-act="v-move"][data-dir="' + d + '"]'); return b ? b.disabled : null; };
          out2.push({ sid, i, len: a.length, left: q(-1), right: q(1), wantLeft: i === 0, wantRight: i === a.length - 1 });
        }
      }
      V.ordering = 'sh2'; resetGrps(); V.ordering = 'sh2'; V.grpOpen.s2 = true; V.tileOn = { sid: 2, slot: mid[1] - 1 }; patch();
      return out2; })(),
    listo: (() => { const b = grpOf('s2').querySelector('[data-act="v-order"][data-scope="sh2"]'); return b ? b.textContent.trim() + '/' + b.className.trim() + '/' + b.getAttribute('aria-pressed') : null; })() };
  V.ordering = null; V.tileOn = null; patch(); await wait(280);

  /* --- P5 (cont.) a search result names the estante; a row inside one does not --- */
  reset(); patch(); await wait(260);
  const f = document.getElementById('lista-q'); f.focus(); f.value = 'a'; f.dispatchEvent(new Event('input', { bubbles: true }));
  await wait(460);
  out.search = { n: main().querySelectorAll('.glist > .grow').length,
    label: main().querySelector('.lhead .group-label').textContent.trim(),
    count: main().querySelector('.gcount').textContent,
    rows: [...main().querySelectorAll('.glist > .grow')].map(x => ({ name: gname(x), sub: x.querySelector('.gsub').textContent.trim(),
      h: Math.round(rr(x).height), lines: Math.round(rr(x.querySelector('.gsub')).height / 16) })),
    heights: [...new Set([...main().querySelectorAll('.glist > .grow')].map(x => Math.round(rr(x).height)))].sort((a, b) => a - b),
    overflowX: sc().scrollWidth - sc().clientWidth, groups: main().querySelectorAll('.grp').length };
  f.value = ''; f.dispatchEvent(new Event('input', { bubbles: true })); await wait(420);

  /* --- P6 the zone derivation, at many shelf lengths (the rule, not one case) --- */
  out.zones = (() => {
    const lens = [1, 2, 3, 5, 13, 37, 54, 65, 162];
    return lens.map(n => {
      const z = Array.from({ length: n }, (_, i) => zoneAt(i, n));
      const idx = z.map(x => ZONES.indexOf(x));
      return { n, first: z[0], last: z[n - 1], distinct: [...new Set(z)].length,
        monotone: idx.every((v, i) => i === 0 || v >= idx[i - 1]),
        inRange: idx.every(v => v >= 0 && v <= 2),
        bands: [0, 1, 2].map(k => idx.filter(v => v === k).length),
        /* the boundary falls where a third falls, within one slot */
        cut1: idx.indexOf(1), cut2: idx.indexOf(2), third: Math.round(n / 3), twoThirds: Math.round(2 * n / 3) };
    });
  })();

  /* --- P8 everything the retired Asignar screen did, from this one page --- */
  reset(); V.grpOpen.s1 = true; patch(); await wait(320);
  document.querySelector('[data-act="v-add-mode"][data-sid="1"]').click(); await wait(360);
  const b8 = { count: shelfCount(shelfById(1)), unplaced: unplacedN(), order: ordOf(1).slice() };
  const addRows = [...grpOf('s1').querySelectorAll('.grow[data-act="v-assign"]')];
  out.add = { mode: V.adding, rows: addRows.length, hint: grpOf('s1').querySelector('.gnote').textContent.trim(),
    cap: (grpOf('s1').querySelector('.more .cap') || {}).textContent,
    progVisible: rr(main().querySelector('.prog')).bottom <= rr(sc()).bottom,
    meter: !!main().querySelector('.prog .meter'),
    /* the add list uses the page's own row anatomy, thumbnail included */
    rowH: Math.round(rr(addRows[0]).height), slot: Math.round(rr(addRows[0].querySelector('.thumb')).width),
    acts: [...grpOf('s1').querySelectorAll('.gacts button')].map(b => b.textContent.trim()) };
  const picked = gname(addRows[0]);
  addRows[0].click(); await wait(600);
  out.add.after = { name: picked, count: shelfCount(shelfById(1)), unplaced: unplacedN(),
    wentToEnd: gById(ordOf(1)[ordOf(1).length - 1]).name,
    grew: ordOf(1).length - b8.order.length, unplacedFell: b8.unplaced - unplacedN(),
    snack: document.querySelector('#snack span').textContent.trim(),
    badge: (document.querySelector('.tabs [data-tab="estantes"] .badge') || {}).textContent || '',
    sum: V.shelves.reduce((a, s) => a + shelfCount(s), 0), placed: placedN(),
    zoneOfNew: zoneAt(idxOn(1, gById(ordOf(1)[ordOf(1).length - 1]).id), ordOf(1).length) };
  document.querySelector('#snack button').click(); await wait(420);
  out.add.undone = { count: shelfCount(shelfById(1)), unplaced: unplacedN() };
  V.adding = null; patch(); await wait(240);

  /* --- P10 the fixture: position is only real if the shelf's whole order exists --- */
  out.fixture = {};
  for (const n of [4, 12]) {
    reset(n);
    out.fixture[n] = { sum: V.shelves.reduce((a, s) => a + shelfCount(s), 0), placed: placedN(), unplaced: unplacedN(), total: TOTAL,
      shelves: V.shelves.map(s => {
        const a = ordOf(s.id), named = a.map((x, i) => [x, i]).filter(([x]) => x != null);
        return { name: s.name, count: a.length, named: named.length,
          contiguous: named.every(([, i], k) => k === 0 || i === named[k - 1][1] + 1),
          run: named.length ? [named[0][1], named[named.length - 1][1]] : null,
          /* a line may only say "entre X y Y" when BOTH adjacent slots are named */
          claims: named.map(([x, i]) => { const line = nbrLine(s.id, i);
            const L = i > 0 && a[i - 1] != null, R = i < a.length - 1 && a[i + 1] != null;
            return { line, honest: /^Entre /.test(line) ? (L && R) : /^Después de /.test(line) ? L : /^Antes de /.test(line) ? R
              : /^Primero/.test(line) ? i === 0 : /^Último/.test(line) ? i === a.length - 1 : /^El \\d/.test(line) ? (!L && !R) : false }; }) };
      }) };
  }
  reset(); go('estantes'); await wait(300);
  return out;
};
/* ================= 065 R9/R10: the estante IS a rail =================
   Developer, R9: "what if we use carousel(horizontal scrolable) to represent that physical position,
   maybe been inspired by Apple iBooks?" — R9 built three variants behind a V.est switch and measured
   the rail as the LOSER at 162 boxes. Developer, R10: "For estantes, I want option B(riel). remove the
   another variants." A and C are deleted, so this probe measures ONE page instead of three, and the
   numbers R9 charged against the rail are re-pointed rather than dropped: the arrow-only trip to the
   middle is still computed (X4), the fade's three states are still counted (X2), and both are now the
   JUSTIFICATION for the zone bar rather than the case against the rail. */
window.__r9 = async () => {
  const rr = e => e.getBoundingClientRect(), cs = e => getComputedStyle(e), wait = ms => new Promise(r => setTimeout(r, ms));
  const sc = () => document.querySelector('#device .scroller');
  const main = () => document.querySelector('#main');
  const rgb = s => { const srgb = /^color\\(srgb/.test(s); const m = s.replace(/^color\\(srgb/, '').match(/[\\d.]+/g).map(Number); const k = srgb ? 255 : 1; return { r: m[0] * k, g: m[1] * k, b: m[2] * k }; };
  const lum = c => [c.r, c.g, c.b].map(v => { v /= 255; return v <= .03928 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4; }).reduce((s, v, i) => s + v * [.2126, .7152, .0722][i], 0);
  const cr = (x, y) => +((Math.max(lum(x), lum(y)) + .05) / (Math.min(lum(x), lum(y)) + .05)).toFixed(2);
  const tok = t => { const d = document.createElement('div'); d.style.color = \`var(\${t})\`; document.body.appendChild(d); const v = cs(d).color; d.remove(); return rgb(v); };
  const open = async sid => {
    Object.assign(V, { listaQ: '', adding: null }); resetGrps();
    V.grpOpen['s' + sid] = true; S.screen = 'estantes'; render(); await wait(400);
  };
  const grp = () => [...main().querySelectorAll('.grp')].find(x => x.querySelector('[aria-expanded="true"]'));
  const out = { set: null };

  /* --- the shipped page on the club's biggest estante (162 boxes). R9's A = 493px and C = 553px are
         recorded constants in the README now; what is measured is that the shipped estante stays under
         the list it replaced even after the zone bar is added to it. --- */
  {
    await open(4);
    const wrap = main().querySelector('.erail-wrap'), rail = wrap.querySelector('.erail');
    const g = grp();
    out.D = {
      openH: Math.round(rr(g).height), pageH: sc().scrollHeight,
      rows: g.querySelectorAll('.grow.gdisc').length,
      railH: +rr(wrap).height.toFixed(1),
      scrollW: rail.scrollWidth, client: rail.clientWidth,
      tiles: g.querySelectorAll('.etile').length, bands: g.querySelectorAll('.egap').length,
      /* 024-A's affordances are still the only ones ON THE RAIL: no indicator element inside it, and no
         per-tile ordinal. The zone bar is a SIBLING, counted separately, and scoped by shelf length. */
      railIndicators: rail.querySelectorAll('.eind, .erail-dots, .erail-bar, .ezones, progress, [role="progressbar"], [role="slider"]').length,
      ordinals: [...g.querySelectorAll('.etile .ecap, .etile .eord')].filter(e => /^\\s*\\d+\\s*(\\/|de)\\s*\\d+/.test(e.textContent)).length,
      subs: [...g.querySelectorAll('.gsub')].map(e => e.textContent.trim()),
      /* focus: the roving tabindex means ONE tab stop for the whole rail */
      stops: [...g.querySelectorAll('button:not([disabled]),a[href],input,[tabindex]')].filter(e => e.tabIndex >= 0 && cs(e).display !== 'none').length,
      tileStops: [...g.querySelectorAll('.etile')].filter(t => t.tabIndex >= 0).length,
      barStops: [...g.querySelectorAll('.ezones .chip')].filter(t => t.tabIndex >= 0).length,
    };
    /* the zone bar, as an object of its own, because X2 asserts where it is as much as what it says */
    const bar = g.querySelector('.ezones');
    out.bar = bar ? { n: bar.querySelectorAll('.chip').length, h: Math.round(rr(bar).height),
      inRail: !!bar.closest('.erail'), aboveRail: Math.round(rr(bar).bottom) <= Math.round(rr(wrap).top) + 1,
      labels: [...bar.querySelectorAll('.chip')].map(x => x.textContent.trim()),
      aria: [...bar.querySelectorAll('.chip')].map(x => x.getAttribute('aria-label')),
      hits: [...bar.querySelectorAll('.chip')].map(x => Math.round(rr(x).height)),
      current: [...bar.querySelectorAll('.chip')].filter(x => x.getAttribute('aria-current') === 'true').length,
      /* the current chip's own state channels, R7b's chip argument applied to a readout */
      state: (() => { const on = bar.querySelector('.chip.on'), off = bar.querySelector('.chip:not(.on)'); if (!on) return null;
        const co = cs(on), cf = cs(off), page = tok('--color-bg');
        return { fillVsPage: cr(rgb(co.backgroundColor), page), labelVsFill: cr(rgb(co.color), rgb(co.backgroundColor)),
          strokeVsPage: cr(rgb(co.borderTopColor), page), weightOn: co.fontWeight, weightOff: cf.fontWeight }; })() } : null;
    /* A and C are DELETED, not parked: no trace in the page this sketch actually serves. Read from the
       SERVED file rather than from outerHTML — the probe is injected as a <script> into the document,
       so scanning outerHTML would find the probe's own regexes and report a trace that is its own. */
    const src = await (await fetch(location.href, { cache: 'no-store' })).text();
    out.gone = { est: (src.match(/V\.est\s*(===|!==|=[^=])/g) || []).length,
      map: (src.match(/erail-wrap\.map/g) || []).length,
      switch: document.querySelectorAll('[data-est]').length, bytes: src.length };
  }

  /* --- the co-dependent measurement set, and the peek it has to leave clear --- */
  await open(4);
  {
    const wrap = main().querySelector('.erail-wrap'), rail = wrap.querySelector('.erail');
    const c = cs(wrap), px = k => parseFloat(c.getPropertyValue(k));
    const w = rr(wrap), kids = [...rail.children].filter(e => e.matches('.etile, .egap'));
    const boxes = kids.map(e => { const r = rr(e); return { l: +(r.left - w.left).toFixed(1), r: +(r.right - w.left).toFixed(1) }; });
    const partial = boxes.find(b => b.l < w.width && b.r > w.width);
    out.set = { tile: px('--etile'), gap: px('--egap'), fade: px('--efade'), gut: px('--egut'),
      wrapW: Math.round(w.width), fullTiles: boxes.filter(b => b.r <= w.width).length,
      peekTotal: partial ? +(w.width - partial.l).toFixed(1) : null,
      peekClear: partial ? +(w.width - px('--efade') - partial.l).toFixed(1) : null,
      tileH: Math.round(rr(main().querySelector('.etile')).height),
      tileW: Math.round(rr(main().querySelector('.etile')).width),
      coverRatio: cs(main().querySelector('.ecover')).aspectRatio };
  }

  /* --- REACHING THE MIDDLE. R9 measured this as 27 arrow presses and called it the number that
         decided the round; R10 ships the rail anyway, so the same number is now the problem the ZONE
         BAR has to answer. Both are measured here: the arrow-only trip (still real — 022-C's arrows
         still exist on a pointer) and the bar, which is DRIVEN, not derived. Plus the worst case over
         every slot, so the bar cannot be credited only with the one target it was built for. --- */
  {
    const wrap = main().querySelector('.erail-wrap'), rail = wrap.querySelector('.erail');
    const c = cs(wrap), px = k => parseFloat(c.getPropertyValue(k));
    const pitch = px('--etile') + px('--egap'), n = ordOf(4).length;
    const midSlot = Math.floor((n - 1) / 2);
    const target = px('--egut') + midSlot * pitch - (rail.clientWidth - px('--etile')) / 2;
    const per = rail.clientWidth * 0.85;
    let presses = 0, at = 0;
    while (at < target - 1 && presses < 999) { at = Math.min(rail.scrollWidth - rail.clientWidth, at + per); presses++; }
    /* the bar, driven: tap "Medio" and read back which box the rail's centre is on */
    const bar = main().querySelector('.ezones');
    bar.querySelector('[data-z="1"]').click(); await wait(460);
    const landed = Math.round((rail.scrollLeft + rail.clientWidth / 2 - px('--egut')) / pitch - 0.5);
    /* worst case with three anchors (the shelf's two ends and its middle box) */
    const anchors = [0, midSlot, n - 1];
    let worst = 0, worstAt = 0;
    for (let sl = 0; sl < n; sl++) { const d = Math.min(...anchors.map(a => Math.abs(a - sl)));
      const pr = Math.ceil(d * pitch / per); if (pr > worst) { worst = pr; worstAt = sl; } }
    out.mid = { slots: n, scrollW: rail.scrollWidth, pxToMiddle: Math.round(target),
      perPress: +per.toFixed(1), cardsPerPress: +(per / pitch).toFixed(2), presses,
      arrowDisplay: cs(wrap.querySelector('.erail-btn')).display,
      barTaps: 1, barLanded: landed, barWant: midSlot, barOff: Math.abs(landed - midSlot),
      barReadout: [...bar.querySelectorAll('.chip')].map(x => x.textContent.trim() + (x.getAttribute('aria-current') === 'true' ? '*' : '')).join(' '),
      worstPresses: worst, worstSlot: worstAt, worstTotal: worst + 1 };
    /* --- AND THE SCRUBBER, built and driven rather than dismissed. A grab handle over the rail's own
           width is the other candidate for "reach the middle of 162", and it is the one Apple reaches
           for once a library stops fitting a shelf (R9's own words). The arithmetic is measured off the
           real geometry: a 44px handle is the touch floor, so the handle is SIX TIMES wider than the
           viewport it stands for, and a 44px fingertip covers as many boxes as the zone bar's anchors
           are apart — i.e. it buys no precision, for a drag, a role="slider" and a 162-state
           indicator. Torn down again immediately; it is a measurement, not a variant. --- */
    const track = document.createElement('div');
    track.id = 'scrub-proto';
    track.style.cssText = 'position:relative;height:44px;margin:0 ' + px('--egut') + 'px;touch-action:none;';
    const handle = document.createElement('div');
    const frac = rail.clientWidth / rail.scrollWidth;
    handle.style.cssText = 'position:absolute;top:0;height:44px;width:' + Math.max(44, (rail.clientWidth - 2 * px('--egut')) * frac) + 'px;';
    track.appendChild(handle); wrap.parentElement.insertBefore(track, wrap);
    await wait(60);
    const tw = rr(track).width, hw = rr(handle).width, travel = tw - hw;
    out.scrub = { trackW: Math.round(tw), handleW: Math.round(hw), travel: Math.round(travel), h: 44,
      handleWanted: +((rail.clientWidth - 2 * px('--egut')) * frac).toFixed(1),
      handleInflation: +(hw / ((rail.clientWidth - 2 * px('--egut')) * frac)).toFixed(1),
      pxPerBox: +(travel / (n - 1)).toFixed(2), boxesPerFinger: Math.round(44 * (n - 1) / travel),
      /* what each control actually costs for an ARBITRARY box, end to end, measured off real geometry:
         the scrubber lands you within half a fingertip and then needs arrow presses like anything else;
         the bar lands you on an anchor and needs presses from there. Both are one gesture to the
         MIDDLE, which was the named problem. */
      resolution: Math.ceil(Math.round(44 * (n - 1) / travel) / 2),
      pressesAfter: Math.ceil(Math.ceil(Math.round(44 * (n - 1) / travel) / 2) * pitch / per),
      worstTotal: 1 + Math.ceil(Math.ceil(Math.round(44 * (n - 1) / travel) / 2) * pitch / per),
      anchorGap: Math.max(...[0, midSlot, n - 1].map((a, i, arr) => i ? Math.ceil((arr[i] - arr[i - 1]) / 2) : 0)) };
    track.remove();
    await open(4);
  }

  /* --- 024: HOW MANY POSITIONS THE EDGE-FADE CAN TELL APART. 024-A chose edge-fade-only for a public
         rail of 8-10 cards, where either end is one fling away. Here the rail is 162 boxes, and its
         two affordances are booleans: content left of the left fade, content right of the right one.
         Sampled across the whole scroll range at 41 offsets. --- */
  {
    const rail = main().querySelector('.erail');
    const max = rail.scrollWidth - rail.clientWidth, seen = {}, mid = [];
    for (let i = 0; i <= 40; i++) {
      rail.scrollLeft = Math.round(max * i / 40);
      const st = (rail.scrollLeft > 0 ? 'L' : '-') + (rail.scrollLeft < max - 1 ? 'R' : '-');
      seen[st] = (seen[st] || 0) + 1;
      if (i > 0 && i < 40) mid.push(st);
    }
    rail.scrollLeft = 0; V.railAt = {};
    out.fade = { states: Object.keys(seen), n: Object.keys(seen).length, census: seen,
      middleAllSame: new Set(mid).size === 1, samples: 41, slots: ordOf(4).length, range: max };
  }

  /* --- THE MARK. 1.4.11 is a 3:1 floor on a component's own state, in BOTH themes, and the obvious
         primary ring does not clear it in dark — the exact shape of the failure round 7 caught. --- */
  {
    await open(4);
    main().querySelector('.etile').click(); await wait(460);
    const on = main().querySelector('.etile.on'), cov = on.querySelector('.ecover'), c = cs(cov);
    const bg = tok('--color-bg'), mk = cs(on.querySelector('.emark')), cap = cs(on.querySelector('.ecap'));
    out.mark = { ringW: c.outlineWidth, ringVsPage: cr(rgb(c.outlineColor), bg),
      primaryVsPage: cr(tok('--color-primary'), bg),
      tickVsBadge: cr(rgb(mk.color), rgb(mk.backgroundColor)),
      capVsFill: cr(rgb(cap.color), rgb(cap.backgroundColor)),
      weightOn: cap.fontWeight, weightOff: cs(main().querySelector('.etile:not(.on) .ecap')).fontWeight,
      aria: on.getAttribute('aria-pressed'),
      /* the tile's accessible name has to SAY the position: a rail's claim is that the eye reads it
         off the geometry, and a screen reader has no geometry. So the words do not go away for AT. */
      label: on.getAttribute('aria-label') };
  }

  /* --- FIXTURE HONESTY AT RAIL DENSITY. Only 36 of the 412 games are named here, so most slots are
         real boxes this sketch cannot title. No cover may imply a game that does not exist: a run of
         them is ONE hatched band of the run's real width, and the rail's geometry stays the shelf's. --- */
  out.honest = [];
  for (const sid of [1, 2, 3, 4]) {
    await open(sid);
    const wrap = main().querySelector('.erail-wrap'), rail = wrap.querySelector('.erail');
    const c = cs(wrap), px = k => parseFloat(c.getPropertyValue(k));
    const pitch = px('--etile') + px('--egap');
    const tiles = [...rail.querySelectorAll('.etile')], bands = [...rail.querySelectorAll('.egap')];
    const bandSlots = bands.reduce((a, e) => a + +e.dataset.n, 0);
    out.honest.push({ sid, slots: ordOf(sid).length, named: ordOf(sid).filter(x => x != null).length,
      tiles: tiles.length, bands: bands.length, bandSlots,
      accountsForAll: tiles.length + bandSlots === ordOf(sid).length,
      extraCovers: tiles.length - ordOf(sid).filter(x => x != null).length,
      geomOff: tiles.filter(t => Math.abs(t.offsetLeft - (px('--egut') + +t.dataset.slot * pitch)) > 0.6).length,
      bandOff: bands.filter(e => Math.abs(rr(e).width - (+e.dataset.n * pitch - px('--egap'))) > 0.6).length,
      scrollW: rail.scrollWidth,
      wantW: Math.round(px('--egut') * 2 + ordOf(sid).length * pitch - px('--egap')),
      caps: bands.map(e => e.textContent.trim()) });
  }

  /* --- THE FLOW THE BRIEF SINGLED OUT: search a game, and the estante's rail opens already scrolled
         to it and marked, with its real neighbours on both sides. R9 drove this in A (the sentence)
         and in B (the picture) and costed B at 214px against A's 78px. R10 ships the picture, and the
         thing it fixes is the half R9 measured B throwing away — the COLLAPSED row, which now keeps
         "zona · estante" so you know which end to walk to before you tap. A's 78px is a recorded
         constant in the README; what is measured here is the combination. --- */
  out.flow = {};
  {
    Object.assign(V, { listaQ: '' }); resetGrps(); S.screen = 'estantes'; render(); await wait(360);
    const f = document.getElementById('lista-q'); f.focus(); f.value = 'dixit';
    f.dispatchEvent(new Event('input', { bubbles: true })); await wait(500);
    const row = main().querySelector('.grow.gdisc');
    const collapsed = { sub: row.querySelector('.gsub').textContent.trim(), h: Math.round(rr(row).height) };
    row.click(); await wait(620);
    const exp = main().querySelector('.gexp'), rail = exp.querySelector('.erail'), on = exp.querySelector('.etile.on');
    const r0 = rr(rail), o0 = rr(on);
    const kids = [...rail.querySelectorAll('.etile, .egap')].filter(e => { const r = rr(e); return r.right > r0.left + 2 && r.left < r0.right - 2; });
    const i = kids.indexOf(on);
    out.flow = { taps: 2, collapsed, expH: Math.round(rr(exp).height),
      isPicture: true, words: exp.querySelectorAll('.nbr').length,
      vis: { n: kids.length, left: i, right: kids.length - 1 - i,
        centred: Math.abs((o0.left + o0.width / 2) - (r0.left + r0.width / 2)) < 24,
        names: kids.map(e => (e.getAttribute('aria-label') || e.textContent).trim().slice(0, 22)) } };
  }

  /* --- THE ZONE WORDS, which is the developer's actual question. R9's census retired them as
         DESCRIPTION inside an estante and kept them in a search result. R10 gives the retired half a
         second job — NAVIGATION — and this section measures both: 0 words inside an estante, the same
         three words as jump targets, and the arithmetic that retired them (unchanged, because it is
         arithmetic: a page of 8 consecutive boxes straddles a third-boundary in only a handful of
         start positions, so one word covered every row of 60–91% of pages). --- */
  {
    Object.assign(V, { listaQ: '' }); resetGrps(); S.screen = 'estantes'; render(); await wait(320);
    const perShelf = [];
    for (const sid of [1, 2, 3, 4]) {
      await open(sid);
      const g = grp();
      const inside = [...g.querySelectorAll('.etile, .ecap, .gsub, .epanel, .gnote, .ename')].filter(e => /Más a la izquierda|Al medio|Más a la derecha/.test(e.textContent));
      const zones = ordOf(sid).map((x, i) => x == null ? null : zoneAt(i, ordOf(sid).length)).filter(Boolean);
      const bar = g.querySelector('.ezones');
      perShelf.push({ sid, n: ordOf(sid).length, rows: g.querySelectorAll('.grow.gdisc').length,
        rowsWithZone: inside.length,
        /* the same vocabulary, as destinations: the full phrase is the accessible name of each jump */
        jumps: bar ? [...bar.querySelectorAll('.chip')].map(x => x.getAttribute('aria-label')) : [],
        jumpLabels: bar ? [...bar.querySelectorAll('.chip')].map(x => x.textContent.trim()) : [],
        renderedZones: [...new Set(zones)], distinct: new Set(zones).size });
    }
    /* the window arithmetic, computed rather than asserted from a hand-derivation */
    const cross = n => { const PAGE = 8, b1 = Math.ceil(n / 3), b2 = Math.ceil(2 * n / 3); let hit = 0, tot = 0;
      for (let s = 0; s + PAGE <= n; s++) { tot++; if ((b1 > s && b1 < s + PAGE) || (b2 > s && b2 < s + PAGE)) hit++; }
      return { n, starts: tot, crossing: hit, oneWordPct: Math.round(100 * (tot - hit) / tot) }; };
    Object.assign(V, { listaQ: '' }); resetGrps(); S.screen = 'estantes'; render(); await wait(300);
    const f = document.getElementById('lista-q'); f.focus(); f.value = 'dixit';
    f.dispatchEvent(new Event('input', { bubbles: true })); await wait(480);
    const sres = [...main().querySelectorAll('.grow.gdisc .gsub')].map(e => e.textContent.trim());
    out.zones = { perShelf, window: [cross(65), cross(59), cross(42), cross(162)], searchA: sres };
  }

  Object.assign(V, { listaQ: '' }); resetGrps(); go('estantes'); await wait(300);
  return out;
};
/* ================= 065 R10: ONE action system, measured across the WHOLE walk =================
   Developer: "Those too big and kill balance ... there are 'text actions' like 'Ver en la ludoteca'
   and 'Quitar del estante'. We need a consistent way to represent actions everywhere with its
   corresponding hierachy and correct balance to fix the currently broken rythm."
   064 owns the per-screen rules (its A1-A9). What only a COMPOSITION can assert is the thing the
   census actually found: the same role rendering two different ways in two different places, one tap
   apart in a walk. So this probe is the census itself — every action on every surface, reduced to
   (context x role -> measured anatomy) - and M1 asserts that each pair has exactly ONE anatomy. */
window.__r10 = async () => {
  const rr = e => e.getBoundingClientRect(), cs = e => getComputedStyle(e), wait = ms => new Promise(r => setTimeout(r, ms));
  const dev = () => document.getElementById('device'), main = () => document.querySelector('#main');
  const sc = () => document.querySelector('#device .scroller');
  const vis = el => { const r = rr(el); if (!r.width || !r.height) return false;
    for (let n = el; n && n !== document.body; n = n.parentElement) { const s = cs(n);
      if (s.visibility === 'hidden' || s.display === 'none' || +s.opacity === 0) return false;
      if (n.matches('.sheet:not(.open), .drawer:not(.open), [inert], [aria-hidden="true"]')) return false; } return true; };
  /* the contexts the census named, most specific first */
  const CTX = ['.dlinks', '.ezones', '.pacts', '.more', '.gxacts', '.emove', '.gtrail', '.ractions', '.lhead',
    '.gacts', '.eactions', '.banner-actions', '.cta2-wrap', '.bgg-more-wrap', '.addrow', '.eback-row', '.trow', '.sfield'];
  const ctxOf = el => CTX.find(c => el.closest(c)) || '(page)';
  /* BACK is its own role, and that is a finding rather than a dodge: the page's back control is a
     leading-glyph NAVIGATION control (4/10px padding, pulled -10px by its chevron), it is identical on
     every drill-down (D1 has asserted that since round 1), and it is page chrome rather than an action
     in the hierarchy. Left folded into TER it put two anatomies in one context x role in the editor's
     back row, next to "Ver en la ludoteca" — which is a real Terciaria action and does have A2's
     anatomy. Naming it is what lets both be right. */
  const roleOf = el => el.matches('.back') ? 'BACK' : el.matches('.dlink') ? 'ROW' : el.matches('.chip') ? 'CHIP'
    : el.matches('.danger') ? 'DAN' : el.matches('.obtn, .b-pri') ? 'PRI' : el.matches('.b-sec') ? 'SEC'
    : el.matches('.ibtn') ? 'ICO' : 'TER';
  const ACT = '.obtn, .tbtn, .b-pri, .b-sec, .cta2, .ibtn, .dlink, .chip, .back';
  const blockOf = el => el.closest('.sheet, .sbox, .banner, .ebar, .grp, .jsec, section, main');
  /* the ANATOMY of one action, with every page-specific number (its label width, its distance from the
     far edge, its position among its siblings) removed, so two pages can be compared at all. */
  const anatomy = el => {
    const c = cs(el), r = rr(el), box = blockOf(el);
    const bs = box ? cs(box) : null, br = box ? rr(box) : null;
    /* WHAT IS DELIBERATELY NOT IN THE FINGERPRINT: how far the action sits from its block's content
       edge. That is a real rule and a real bug was found in it (.pacts pulled an outlined button
       12px past the page's left edge), but it belongs to 064's A2/A3, which judge it per screen with
       the right condition — only for an action that actually TOUCHES an edge. In a strip of three
       chips the middle one is simply where its siblings put it, and folding that into the fingerprint
       would report one control as three anatomies. Measured, then dropped: this is a probe artefact,
       not drift. What stays is full-width vs inline, which IS an anatomy. */
    const st = cs(el.parentElement), g = st.columnGap === 'normal' ? '0px' : st.columnGap;
    const bw = c.borderTopStyle === 'none' ? '0px' : c.borderTopWidth;
    const full = box && r.width >= (br.width - parseFloat(bs.paddingLeft) - parseFloat(bs.paddingRight)) * 0.9;
    /* a row's rendered height grows when its label wraps (061, by design; D5 measures the declared
       minimum for the same reason), and WEIGHT is a state channel on a chip, not an anatomy — R7b put
       the selected state on 600 deliberately. So the fingerprint takes the declared height and drops
       the weight wherever the control carries a state. */
    const h = c.minHeight && c.minHeight !== 'auto' && c.minHeight !== '0px' ? c.minHeight : Math.round(r.height) + 'px';
    const stateful = el.matches('.chip, [aria-current], [aria-pressed]');
    return 'h' + h + ' p' + c.paddingLeft + '/' + c.paddingRight + ' ' + c.fontSize + '/' + (stateful ? 'state' : c.fontWeight)
      + ' b' + bw + ' r' + c.borderTopLeftRadius + ' ' + (full ? 'full' : 'inline') + ' gap' + g;
  };
  /* which of the FOUR anatomies this is — there may be no fifth */
  const kind = el => el.matches('.dlink') ? 'A4' : el.matches('.chip') ? 'CHIP'
    : el.matches('.obtn, .b-pri, .b-sec') ? 'A1' : el.matches('.ibtn') ? 'A3' : 'A2';
  const SURF = [
    ['admin', () => go('panel')],
    ['juegos', () => go('juegos')],
    ['web', () => go('secciones')],
    ['seccion-dirty', () => { V.cur = 1; V.ed = null; V.memQ = ''; go('seccion'); }],
    ['estantes', () => { V.listaQ = ''; resetGrps(); go('estantes'); }],
    ['estante-abierto', () => { V.listaQ = ''; resetGrps(); V.grpOpen.s1 = true; go('estantes'); }],
    ['estante-ordenando', () => { V.listaQ = ''; resetGrps(); V.grpOpen.s1 = true; V.ordering = 'sh1'; V.tileOn = { sid: 1, slot: 1 }; go('estantes'); }],
    ['estante-agregando', () => { V.listaQ = ''; resetGrps(); V.grpOpen.s1 = true; V.adding = 1; V.addShown = 8; go('estantes'); }],
    ['niveles', () => go('niveles')],
    ['staff', () => go('staff')],
    /* the editor is where .eback-row, .cta2-wrap, .bgg-more-wrap and the save bar live — i.e. where
       five of the census's context x role pairs only ever appear. Leaving it out of the walk is how a
       cross-page rule ends up asserting nothing, so all three Estado states are here. */
    ['editor-borrador', () => { openEditor(J.games.find(g => g.bgg === 224517)); E.status = 'draft'; go('editar'); }],
    ['editor-publicado', () => { openEditor(J.games.find(g => g.bgg === 224517)); E.status = 'published'; go('editar'); }],
    ['editor-bgg-failed', () => { openEditor(J.games.find(g => g.bgg === 224517)); E.status = 'published'; E.failed = true; go('editar'); }],
    /* dirty, so the save bar renders its real pairs — [Guardar][Publicar] on a draft and
       [Retirar de la web] ... [Guardar] on a published one, which is 064's Estado matrix and the one
       block in the admin that legitimately holds a Secundaria AND a Principal at once. */
    ['editor-borrador-sucio', () => { openEditor(J.games.find(g => g.bgg === 224517)); E.status = 'draft'; E.ed.name = E.ed.name + ' (ES)'; go('editar'); }],
    ['editor-publicado-sucio', () => { openEditor(J.games.find(g => g.bgg === 224517)); E.status = 'published'; E.ed.name = E.ed.name + ' (ES)'; go('editar'); }],
  ];
  const out = { pairs: {}, kinds: {}, pages: {}, floor: [] };
  const census = (where) => {
    for (const el of dev().querySelectorAll(ACT)) {
      if (!vis(el) || el.closest('.snack')) continue;
      const key = ctxOf(el) + ' × ' + roleOf(el), a = anatomy(el);
      (out.pairs[key] = out.pairs[key] || {});
      (out.pairs[key][a] = out.pairs[key][a] || []).push(where + ':' + (el.textContent.trim() || el.getAttribute('aria-label') || '·').slice(0, 18));
      out.kinds[kind(el)] = (out.kinds[kind(el)] || 0) + 1;
    }
    /* the 44px hit floor, across every tappable thing and not only buttons */
    for (const el of dev().querySelectorAll(ACT + ', button.srow, label.srow, a.srow, .grow, .grow .gmain')) {
      if (!vis(el) || el.closest('.snack')) continue;
      /* getComputedStyle's SECOND argument is the pseudo-element; cs() above takes one, so it has to
         be called directly here — with cs(el, '::after') the chip's -6px bleed is silently invisible
         and a legal 44px target reports as 32. (Measured: the same shape of harness bug as the srgb
         contrast parser round 1 caught.) */
      const r = rr(el), af = getComputedStyle(el, '::after'), t = parseFloat(af.top), b = parseFloat(af.bottom);
      const hit = af.content !== 'none' && !isNaN(t) && !isNaN(b) ? r.height - t - b : r.height;
      if (hit < 43.5) out.floor.push(where + ': ' + (el.textContent.trim() || el.className).slice(0, 18) + ' ' + Math.round(hit) + 'px');
    }
  };
  for (const [name, setup] of SURF) {
    Object.assign(V, { listaQ: '', memQ: '' }); resetGrps(); setup(); await wait(420);
    if (name === 'seccion-dirty') { const i = document.getElementById('ed-name'); if (i) { i.value += ' 2'; i.dispatchEvent(new Event('input', { bubbles: true })); await wait(240); } }
    /* per-page balance: how many outlined actions the page carries, and where. Three equal
       Secundarias and no Principal is the shape of "too big and kill balance". */
    const acts = [...main().querySelectorAll(ACT)].filter(el => vis(el) && !el.closest('.snack'));
    const outl = acts.filter(el => el.matches('.obtn, .b-pri, .b-sec'));
    let bold = 0, total = 0;
    for (const el of main().querySelectorAll('*')) {
      if (!vis(el)) continue;
      const own = [...el.childNodes].filter(n => n.nodeType === 3 && n.textContent.trim()).map(n => n.textContent.trim()).join(' ');
      if (!own) continue; total += own.length; if (+cs(el).fontWeight >= 600) bold += own.length;
    }
    /* per BLOCK, which is where the rule actually bites: "Ordenar" belongs to the list block and
       "Agregar juegos" to the open estante's block, so two outlines on one page is one each and legal.
       Two in ONE block, of one rank, is the pile-up the developer was looking at. */
    const blocks = new Map();
    for (const el of outl) { const b = blockOf(el); if (!b) continue; if (!blocks.has(b)) blocks.set(b, []); blocks.get(b).push(el); }
    out.pages[name] = { actions: acts.length, outlined: outl.length,
      pri: outl.filter(el => el.matches('.obtn, .b-pri')).length, sec: outl.filter(el => el.matches('.b-sec')).length,
      labels: outl.map(el => el.textContent.trim()),
      blocks: [...blocks].map(([b, list]) => ({ cls: (b.className.trim().split(/\s+/)[0] || b.tagName.toLowerCase()),
        pri: list.filter(el => el.matches('.obtn, .b-pri')).length, sec: list.filter(el => el.matches('.b-sec')).length,
        labels: list.map(el => el.textContent.trim()) })),
      pacts: [...main().querySelectorAll(ACT.split(', ').map(x => '.pacts ' + x).join(', '))].filter(vis).map(el => ({ cls: el.className.trim(), outlined: el.matches('.obtn, .b-pri, .b-sec') })),
      actionPx: Math.round(acts.reduce((a, e) => { const r = rr(e); return a + r.width * r.height; }, 0)),
      pagePx: Math.round(rr(main()).width * sc().scrollHeight),
      boldPct: total ? +(100 * bold / total).toFixed(1) : 0 };
    census(name);
  }
  /* LEAVE THE EDITOR CLEAN before the walk moves on. The two dirty editor surfaces above are the only
     states in this probe that make leaving a page ASK something: 063's unsaved-changes sheet. Left
     dirty, the very next go() opens that sheet instead of navigating, and every surface measured after
     it is the editor wearing another page's name — which is exactly what the second theme's pass
     reported before this line existed. */
  if (typeof E !== 'undefined' && E && E.saved) E.ed = JSON.parse(JSON.stringify(E.saved));
  closeAll();
  /* and every sheet in the walk: a sheet has no buttons at all (R7b), its actions are rows */
  out.sheets = [];
  const fake = (act, extra) => { const b = document.createElement('button'); b.dataset.act = act; Object.assign(b.dataset, extra || {}); document.body.appendChild(b); return b; };
  V.listaQ = ''; resetGrps(); V.grpOpen.s1 = true; go('estantes'); await wait(420);
  for (const [name, mk] of [['opciones del estante', () => vAct(fake('v-shelf-sheet', { id: '1' }))],
    ['renombrar', () => vAct(fake('v-rename', { id: '1' }))], ['nuevo estante', () => vAct(fake('v-new-shelf'))],
    ['ubicar', () => vAct(fake('v-place-sheet', { id: String(unplacedLocal()[0].id) }))]]) {
    closeAll(); await wait(200); mk(); await wait(360);
    const sh = dev().querySelector('.sheet.open');
    out.sheets.push({ name, open: !!sh,
      buttons: sh ? [...sh.querySelectorAll('.obtn, .tbtn, .b-pri, .b-sec, .cta2')].filter(vis).length : null,
      rows: sh ? [...sh.querySelectorAll('.dlinks .dlink')].filter(vis).map(r => r.textContent.trim().slice(0, 18)) : [],
      heights: sh ? [...new Set([...sh.querySelectorAll('.dlinks .dlink')].filter(vis).map(r => cs(r).minHeight))] : [] });
    census('hoja: ' + name);
  }
  closeAll(); V.listaQ = ''; resetGrps(); go('estantes'); await wait(300);
  return out;
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
    await p.waitForTimeout(420);   /* softSwap holds the old body for 230ms; 260 measured mid-swap */
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
    '5-web': 'secciones', '6-seccion': 'secciones', '7-estantes': 'estantes', '8-estante-abierto': 'estantes' };
  for (const [n, want] of Object.entries(tabOf))
    ok(by(n).activeTab[0] === want, `${n}: the ${want} tab is the one lit (got ${by(n).activeTab[0] || 'none'})`);

  /* --- D1 page head: every drill-down uses the same back row, in the same place ---
     065 R8: this rule had three subjects and now has two. Asignar was the third, and it is retired —
     so the rule does not lose an assertion, it loses a SUBJECT, and the thing that inherited its job
     is asserted instead just below (P1: an expanded estante never navigates, so the lit tab cannot
     drift and there is no back row to align). */
  const drill = ['3-editor', '6-seccion'];
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
  /* 065 R8: the assignment used to be driven on the Asignar screen. It is driven on the estante that
     inherited the job — open estante 1, enter "Agregar juegos", tap the first unplaced game. */
  await p.evaluate(() => { V.listaQ = ''; V.ordering = null; resetGrps(); V.grpOpen.s1 = true; go('estantes'); });
  await p.waitForTimeout(420);
  await p.evaluate(() => document.querySelector('[data-act="v-add-mode"][data-sid="1"]').click());
  await p.waitForTimeout(360);
  await p.evaluate(() => { document.querySelector('[data-act="v-assign"]').click(); });
  await p.waitForTimeout(600);
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
    /* 065 R7b added these four to the walk: renombrar was the sheet with the Cancelar/Guardar footer
       and, because nothing had ever measured it, also the one sheet whose label sat INSIDE its form
       (labelGap −16.5px against every other sheet's 4px). */
    /* 065 R8: renombrar keeps its place in the walk and changes where it is reached from — an
       estante's own options sheet, since the screen whose title bar used to carry the button is gone.
       Three surfaces the round added join it: that options sheet, the Ubicar-en picker a Sin ubicar
       row opens, and "Nuevo estante", which became a sheet this round. */
    renombrar: "V.listaQ='';V.ordering=null;resetGrps();V.grpOpen.s1=true;go('estantes'); setTimeout(()=>{document.querySelector('[data-act=\"v-shelf-sheet\"][data-id=\"1\"]').click(); setTimeout(()=>document.querySelector('#sheet-act [data-act=\"v-rename\"]').click(),260);},340);",
    'opciones-estante': "V.listaQ='';V.ordering=null;resetGrps();V.grpOpen.s1=true;go('estantes'); setTimeout(()=>document.querySelector('[data-act=\"v-shelf-sheet\"][data-id=\"1\"]').click(),340);",
    ubicar: "V.listaQ='';V.ordering=null;resetGrps();V.grpOpen.sin=true;go('estantes'); setTimeout(()=>document.querySelector('[data-act=\"v-place-sheet\"]').click(),340);",
    'nuevo-estante': "V.listaQ='';V.ordering=null;resetGrps();go('estantes'); setTimeout(()=>document.querySelector('[data-act=\"v-new-shelf\"]').click(),340);",
    orden: "V.cur=1;V.ed=null;go('seccion'); setTimeout(()=>document.querySelector('[data-act=\"v-sort-sheet\"]').click(),320);",
    staff: "go('staff'); setTimeout(()=>document.querySelector('[data-act=\"v-staff-sheet\"]').click(),320);",
    /* two steps deep: the sheet, then its confirm step, which slides — R6 measures the row inset, so it
       has to be measured after the slide, not during it. */
    quitar: "go('staff'); setTimeout(()=>{document.querySelector('[data-act=\"v-staff-sheet\"]').click(); setTimeout(()=>document.querySelector('[data-act=\"v-staff-confirm\"]').click(),260);},260);",
  };
  const shell = {};
  for (const [name, setup] of Object.entries(SHEETS)) {
    await p.evaluate(() => closeAll());
    await p.evaluate(x => { try { (0, eval)(x); } catch (e) {} }, setup);
    await p.waitForTimeout(1000);
    const sh = await p.evaluate(() => {
      const el = document.querySelector('.sheet.open'); if (!el) return null;
      const cs = e => getComputedStyle(e), rr = e => e.getBoundingClientRect();
      const step = el.querySelector('.step:not([aria-hidden="true"])') || el;
      const lbl = step.querySelector('.group-label');
      const first = [...step.children].find(c => c !== lbl && rr(c).height);
      const rows = [...step.querySelectorAll('.dlink, .srow')].filter(r => rr(r).height);
      /* 065 R7b: a sheet's actions are ROWS. Anything that looks like a button footer — a
         .banner-actions strip, or any 064 button rung standing loose in the sheet — is the thing this
         rule exists to forbid, so it is measured, not assumed. */
      const acts = [...step.querySelectorAll('.dlink')].filter(r => rr(r).height).map(r => ({
        label: (r.querySelector('.lbl') || r).textContent.trim().replace(/\s+/g, ' ').slice(0, 26),
        chev: !!r.querySelector('.chev'), type: r.getAttribute('type'),
        danger: r.classList.contains('danger'), ico: !!r.querySelector('.slot svg'),
        isStatic: r.classList.contains('static') }));
      return { pad: cs(el).padding, grab: cs(el.querySelector('.grab')).margin,
        label: lbl ? `${cs(lbl).fontSize}/${cs(lbl).fontWeight}/${cs(lbl).textTransform}` : null,
        labelGap: (lbl && first) ? Math.round(rr(first).top - rr(lbl).bottom) : null,
        minRow: [...new Set(rows.map(r => cs(r).minHeight))].sort().join(','),
        rowInset: Math.round(rr(rows[0]).left - rr(el).left),
        navRowsMissingChev: rows.filter(r => /Ver (el sitio|en la)/.test(r.textContent) && !r.querySelector('.chev')).map(r => r.textContent.trim().slice(0, 22)),
        footers: [...step.querySelectorAll('.banner-actions')].filter(f => rr(f).height).map(f => f.className),
        looseBtns: [...step.querySelectorAll('.obtn, .b-pri, .b-sec, .tbtn')].filter(x => rr(x).height)
          .map(x => x.className.trim() + '“' + x.textContent.trim().slice(0, 18) + '”'),
        acts };
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

  /* --- C8 (065 R7b) a sheet's actions are ROWS, never a button footer ---------------------------
     Measured across the whole walk, two sheets had one: Asignar's Renombrar (a Terciaria "Cancelar"
     beside a Principal "Guardar") and the editor's Filas del inicio (a lone Terciaria "Listo") —
     while confirmRemove, the Nivel sheet, Orden, the member sheet and the Staff sheet all build
     their actions as 48px full-bleed .dlinks rows. One pattern now, asserted on every sheet so a
     seventh cannot reintroduce a footer. */
  const withFooter = Object.entries(shell).filter(([, v]) => v.footers.length || v.looseBtns.length);
  ok(withFooter.length === 0,
    `C8 no sheet in the walk has a button footer (${withFooter.map(([n, v]) => n + ':' + [...v.footers, ...v.looseBtns].join(' ')).join(' | ') || Object.keys(shell).length + ' sheets, all .dlinks rows'})`);
  const cancels = Object.entries(shell).filter(([, v]) => v.acts.some(a => /^Cancelar$/.test(a.label)));
  const badCancel = cancels.filter(([, v]) => { const a = v.acts.filter(x => !x.isStatic); const last = a[a.length - 1];
    return !/^Cancelar$/.test(last.label) || last.chev !== false || !last.ico; });
  ok(cancels.length >= 3 && badCancel.length === 0,
    `C8 where a sheet has a Cancelar it is the last row and carries chevL (${cancels.map(([n, v]) => n + ':' + v.acts.filter(x => !x.isStatic).map(a => a.label).join('→')).join(' | ')})`);
  const ren = shell.renombrar;
  ok(ren && ren.acts.length === 2 && ren.acts[0].label === 'Guardar' && ren.acts[0].type === 'submit' && ren.acts[0].ico
    && ren.acts[1].label === 'Cancelar',
    `C8 the rename sheet commits from a row that IS the form's submit, first, with its icon (${ren && ren.acts.map(a => a.label + '/' + a.type).join(' → ')})`);
  ok(shell.filas && shell.filas.acts.some(a => a.label === 'Listo'),
    `C8 the editor's Filas sheet closes from a row too (${shell.filas && shell.filas.acts.map(a => a.label).join(' → ')})`);
  await p.evaluate(() => closeAll());

  /* --- C8 (cont.) the one sheet with a form still validates inline and still commits by keyboard ---
     This is where a row genuinely might have broken the sheet, so it is driven end to end rather
     than inspected: an empty name and a duplicate name each have to report in the sheet without
     closing it, and Enter and a tap on the row have to commit exactly once each. */
  const renForm = [];
  for (const [what, value, expect] of [['vacío', '', 'Poné un nombre.'], ['duplicado', 'Estante B — estrategia', 'Ya hay un estante con ese nombre.']]) {
    await p.evaluate(() => { V.listaQ = ''; V.ordering = null; resetGrps(); V.grpOpen.s1 = true; go('estantes'); });
    await p.waitForTimeout(440);
    await p.evaluate(() => document.querySelector('[data-act="v-shelf-sheet"][data-id="1"]').click());
    await p.waitForTimeout(300);
    await p.evaluate(() => document.querySelector('#sheet-act [data-act="v-rename"]').click());
    await p.waitForTimeout(420);
    await p.evaluate(v => { const i = document.getElementById('ren-in'); i.focus(); i.value = v; i.dispatchEvent(new Event('input', { bubbles: true })); }, value);
    await p.waitForTimeout(140);
    await p.keyboard.press('Enter');
    await p.waitForTimeout(380);
    const st = await p.evaluate(() => ({ open: !!document.querySelector('.sheet.open'),
      err: document.querySelector('#sheet-act .ferr')?.textContent.trim() || '',
      invalid: !!document.getElementById('ren-in')?.classList.contains('invalid'),
      focus: document.activeElement?.id, name: shelfById(V.curShelf).name }));
    renForm.push([what, expect, st]);
    await p.evaluate(() => closeAll());
    await p.waitForTimeout(220);
  }
  for (const [what, expect, st] of renForm)
    ok(st.open && st.err === expect && st.invalid && st.focus === 'ren-in' && st.name === 'Estante A — familiares',
      `C8 a ${what} name reports in the sheet without closing it (“${st.err}”, abierta ${st.open}, foco ${st.focus}, nombre “${st.name}”)`);
  for (const [how, commit] of [['con Enter', null], ['tocando la fila', '[...document.querySelectorAll("#sheet-act .dlink")].find(r => /Guardar/.test(r.textContent)).click()']]) {
    await p.evaluate(() => { Object.assign(V, seed062(true)); V.listaQ = ''; V.ordering = null; resetGrps(); V.grpOpen.s1 = true; go('estantes'); });
    await p.waitForTimeout(440);
    await p.evaluate(() => document.querySelector('[data-act="v-shelf-sheet"][data-id="1"]').click());
    await p.waitForTimeout(300);
    await p.evaluate(() => document.querySelector('#sheet-act [data-act="v-rename"]').click());
    await p.waitForTimeout(420);
    await p.evaluate(() => { const i = document.getElementById('ren-in'); i.focus(); i.value = 'Estante Ñ — probado'; i.dispatchEvent(new Event('input', { bubbles: true })); });
    await p.waitForTimeout(140);
    if (commit) await p.evaluate(c => (0, eval)(c), commit); else await p.keyboard.press('Enter');
    await p.waitForTimeout(650);
    const st = await p.evaluate(() => ({ open: !!document.querySelector('.sheet.open'), name: shelfById(V.curShelf).name,
      snack: document.querySelector('#snack')?.textContent.trim(),
      once: V.shelves.filter(s => s.name === 'Estante Ñ — probado').length }));
    ok(!st.open && st.name === 'Estante Ñ — probado' && st.once === 1 && /renombrado/i.test(st.snack || ''),
      `C8 renaming commits ${how} exactly once (“${st.name}” ×${st.once}, hoja abierta ${st.open}, “${st.snack}”)`);
  }
  await p.evaluate(() => { Object.assign(V, seed062(true), { ed: null, ordering: null, memQ: '', listaQ: '' }); resetGrps(); closeAll(); });
  await p.waitForTimeout(240);

  /* ================= C. one component per job (065 R7) =================
     Four developer notes on a sección, and each one turned out to be a second implementation of
     something the admin already had: two surfaces inside one labelled block, a save bar the editor had
     already designed, a mode toggle rendered as a text link, and a search that rebuilt its own field on
     every keystroke. Measured in both themes at phone width; the desktop pass repeats C1/C3/C4. */
  for (const theme of ['light', 'dark']) {
    await p.evaluate(t => t === 'dark' ? document.documentElement.dataset.theme = 'dark' : delete document.documentElement.dataset.theme, theme);
    const C = await p.evaluate(() => window.__r7());
    const T = `C ${theme}`;

    /* --- C1 the Ajustes block is ONE surface on ONE rhythm ---------------------------------------
       Before: a section label, two fields bare on the page background, then a soft box holding the two
       setting rows — one labelled block, two surface treatments, gaps of 8/6/12/6/16px down its middle. */
    ok(C.panel.strays.length === 0,
      `C1 ${theme}: every Ajustes control is inside the one block (outside: ${C.panel.strays.join(', ') || 'none'})`);
    const pg = [...new Set(C.panel.gaps)];
    ok(pg.length === 1, `C1 ${theme}: one gap between every child of the Ajustes panel (${C.panel.gaps.join(' / ')} — ${C.panel.kids.join(' · ')})`);
    ok(C.panel.padTop === C.panel.padBottom && C.panel.padTop === pg[0],
      `C1 ${theme}: the panel's top and bottom padding are even and on the rhythm (${C.panel.padTop} / ${C.panel.padBottom}, rhythm ${pg[0]})`);
    ok(C.panel.labelGap * 2 === pg[0],
      `C1 ${theme}: a field label sits a half step over its own input (${C.panel.labelGap} of ${pg[0]})`);
    ok(C.panel.fill !== C.panel.pageFill,
      `C1 ${theme}: the panel really is a block, not the page (${C.panel.fill} on ${C.panel.pageFill})`);
    const weak = C.panel.strokes.filter(s => parseFloat(s.bw) !== 1 || s.vsPanel < 3);
    ok(weak.length === 0,
      `C1 ${theme}: a field on the tinted panel keeps a 1px stroke over 3:1 (${C.panel.strokes.map(s => s.id + ' ' + s.bw + ' ' + s.vsPanel + ':1').join(' · ')})`);

    /* --- C2 the form and the search are told apart by their BLOCK, not by their anatomy ----------
       Round 4 gave the search field the same anatomy as every other field on purpose (F1 still asserts
       it), so the only thing left that can separate them is which block each one is in. */
    const inPanel = C.fieldBlocks.filter(f => f.inPanel), onPage = C.fieldBlocks.filter(f => !f.inPanel);
    ok(inPanel.length >= 2 && onPage.length === 1 && onPage[0].id === 'mem-q',
      `C2 ${theme}: the form is in the panel and the search is the only field on the page background (${C.fieldBlocks.map(f => f.id + (f.inPanel ? ' ⟨panel⟩' : ' ⟨page⟩') + ' ' + f.behind).join(' · ')})`);
    ok(new Set(C.fieldBlocks.map(f => f.behind)).size === 2,
      `C2 ${theme}: and the two groups really sit on different surfaces (${[...new Set(C.fieldBlocks.map(f => f.behind))].join(' vs ')})`);

    /* --- C3 there is exactly ONE save bar in the admin ------------------------------------------- */
    ok(C.barCensus.second.length === 0,
      `C3 ${theme}: no second save-bar implementation is left (${C.barCensus.second.join(', ') || '.saverow / .dirty-note gone'})`);
    const sigOf = b => b.split(':').slice(1).join(':').replace(/ \(pad .*/, '');
    const barSigs = [...new Set(C.barCensus.bars.map(sigOf))];
    ok(barSigs.length === 1 && C.barCensus.bars.length >= 2,
      `C3 ${theme}: every save bar in the admin is the same block (${C.barCensus.bars.join(' | ')})`);
    for (const key of ['cls', 'pad', 'gap', 'fill', 'radius', 'bw', 'dir', 'bl1'])
      ok(String(C.secBarDirty[key]) === String(C.editorBarDirty[key]),
        `C3 ${theme}: a sección's save bar and the editor's share ${key} (${C.secBarDirty[key]} / ${C.editorBarDirty[key]})`);
    ok(C.secBarDirty.actH.join() === C.editorBarDirty.actH.join() && C.secBarDirty.actH[0] === 44,
      `C3 ${theme}: and one action height (${C.secBarDirty.actH.join()} / ${C.editorBarDirty.actH.join()})`);
    for (const [n, bar] of [['sección', C.secBarDirty], ['editor', C.editorBarDirty]])
      ok(Math.abs(bar.lastRight - bar.contentEdge) <= 0.5 && Math.abs(bar.top - bar.bottom) <= 2,
        `C3 ${theme}: the ${n} bar's Principal lands on the content edge and the box breathes evenly (${bar.lastRight} vs ${bar.contentEdge}; ${bar.top} / ${bar.bottom})`);
    ok(C.secBarClean.acts.length === 0 && /Todo guardado/.test(C.secBarClean.text) && C.secBarClean.dot
      && Math.abs(C.secBarClean.top - C.secBarClean.bottom) <= 2,
      `C3 ${theme}: with nothing to save the bar states it, with its dot, and still breathes evenly (“${C.secBarClean.text}” ${C.secBarClean.top} / ${C.secBarClean.bottom})`);
    ok(/Cambios sin guardar/.test(C.secBarDirty.text) && C.secBarDirty.acts.length === 1 && /obtn/.test(C.secBarDirty.acts[0]),
      `C3 ${theme}: dirty, it says so and carries exactly one Principal (“${C.secBarDirty.text}” ${C.secBarDirty.acts.join()})`);
    ok(C.secBarDirty.seam === 12,
      `C3 ${theme}: the bar and the settings panel keep a seam on the panel's own rhythm (${C.secBarDirty.seam}px)`);
    ok(C.secBarKeptTheField,
      `C3 ${theme}: typing the section's name swaps the bar, not the field (${C.secBarKeptTheField})`);

    /* --- C4 the reorder toggle is a real button, in both states, on all three pages -------------- */
    for (const [page, t] of Object.entries(C.toggles)) {
      for (const [state, s] of [['Ordenar', t.off], ['Listo', t.on]]) {
        ok(s.bw === 1 && s.borderVsBg >= 3,
          `C4 ${theme} ${page}: “${s.text}” carries a real 1px stroke over 3:1 (${s.bw}px, ${s.borderVsBg}:1)`);
        ok(s.h === 44 && Math.abs(s.right - s.edge) <= 0.5,
          `C4 ${theme} ${page}: “${s.text}” is a 44px control ending on the row's content edge (${s.h}px, ${s.right} vs ${s.edge})`);
      }
      ok(t.off.pressed === 'false' && t.on.pressed === 'true' && t.off.text === 'Ordenar' && t.on.text === 'Listo' && t.backTo === 'Ordenar',
        `C4 ${theme} ${page}: aria-pressed follows the mode (${t.off.text}/${t.off.pressed} → ${t.on.text}/${t.on.pressed} → ${t.backTo})`);
      ok(t.off.border !== t.on.border,
        `C4 ${theme} ${page}: the on state is visibly the on state, not just a different word (${t.off.cls} ${t.off.border} → ${t.on.cls} ${t.on.border})`);
      ok(Math.abs(t.off.mid - t.off.lblMid) <= 0.5 && Math.abs(t.on.mid - t.on.lblMid) <= 0.5,
        `C4 ${theme} ${page}: the control and its label share the row's middle (${t.off.mid} / ${t.off.lblMid}, row ${t.off.rowH}px)`);
    }
    const offMid = C.countHeads.filter(h => Math.abs(h.delta) > 0.5);
    ok(offMid.length === 0,
      `C4 ${theme}: every other lhead right slot still sits on its label's middle (${C.countHeads.map(h => h.where + ' ' + h.delta).join(' · ')})`);

    /* --- C5 typing in a search never replaces the field ----------------------------------------- */
    for (const [id, t] of Object.entries(C.typing)) {
      ok(t.sameNode && t.focused, `C5 ${theme} ${id}: the input node survives typing (same node ${t.sameNode}, still focused ${t.focused})`);
      ok(t.boxes.length === 1, `C5 ${theme} ${id}: its rendered box never moves between keystrokes (${t.boxes.join(' | ')})`);
      ok(t.carets.join() === t.carets.map((_, i) => i + 1).join(), `C5 ${theme} ${id}: the caret never jumps (${t.carets.join(',')} for “${t.value}”)`);
      ok(t.regionThere && t.changed > 0, `C5 ${theme} ${id}: it refreshes #${t.region} instead (${t.changed} chars of results)`);
    }
  }
  await p.evaluate(() => delete document.documentElement.dataset.theme);

  /* ================= C6/C7 (065 R7b, re-based by R8) the collapsed estante list =================
     R7b's grouped view scaled and survives the restructure, so C6 keeps every assertion and only
     changes its setup (there is no view to switch into any more) — except its last pair, which was
     "searching keeps every group's heading (E5)". That rule existed because the HEADING was the only
     thing that could say which estante a hit sat on. Round 8 put that on the row, so the rule keeps
     its job and changes its carrier: a query answers in one row that names the estante, instead of
     thirteen headings you then have to hunt through. It is asserted in that form below.
     C7 loses an instance, not a rule: the view switch it was written for is retired, so the chip
     assertions run on 061's four filter chips — still the admin's one "pick one of N" — and what is
     asserted about Estantes is the opposite claim, that it carries no view control at all. */
  for (const theme of ['light', 'dark']) {
    await p.evaluate(t => t === 'dark' ? document.documentElement.dataset.theme = 'dark' : delete document.documentElement.dataset.theme, theme);
    const B = await p.evaluate(() => window.__r7b());

    /* --- C6 the list scales, and never claims a count it cannot show ------------------------------ */
    for (const n of ['4', '12']) {
      const g = B.grouped[n];
      ok(g.collapsed.groups.every(x => x.named && x.visible),
        `C6 ${theme} ${n} estantes: every estante names itself with its own disclosure row and every heading is on the page (${g.collapsed.groups.length} grupos, ${g.collapsed.groups.filter(x => x.named).length} con nombre)`);
      const hdrs = [...new Set(g.collapsed.groups.map(x => x.h))];
      ok(hdrs.length === 1 && hdrs[0] <= 68,
        `C6 ${theme} ${n} estantes: a shut estante costs exactly one row (${hdrs.join('/')}px each, ${g.collapsed.groups.length} of them)`);
      ok(g.collapsed.screens <= 2,
        `C6 ${theme} ${n} estantes: the whole page is ${g.collapsed.h}px = ${g.collapsed.screens} screens (was 1702px = 2.30 screens with four, before R7b)`);
      ok(g.collapsed.sumShelf === g.collapsed.placed && g.collapsed.placed + g.collapsed.unplaced === g.collapsed.total,
        `C6 ${theme} ${n} estantes: the counts add up (Σestantes ${g.collapsed.sumShelf} = ubicados ${g.collapsed.placed}, +${g.collapsed.unplaced} sin ubicar = ${g.collapsed.total})`);
      /* 065 R10 RE-POINTS THIS PAIR, because the developer promoted R9's B and an estante's contents
         are the rail's tiles now. The RULE is unchanged — an estante that claims a count must open to
         something real, and what it cannot show must be offered rather than captioned. What changes is
         the carrier and, with it, the shape of the second half: a rail shows the WHOLE shelf, so there
         is nothing left to page and no "Mostrar más" to lie about. The honest-caption job moved to the
         hatched bands (X8), so what is asserted here is that no estante has a dead-end caption at all.
         "Sin ubicar" is the one group that still opens to ROWS, and it keeps its pagination. */
      const empty = g.expanded.groups.filter(x => x.rows === 0 && x.slots === 0);
      ok(empty.length === 0,
        `C6 ${theme} ${n} estantes: every estante opens to something real — a rail of its own slots, or rows for Sin ubicar (${g.expanded.groups.map(x => x.tiles ? x.tiles + '+' + (x.slots - x.tiles) + ' cajas' : x.rows + ' filas').join(' · ')}; vacíos: ${empty.map(x => x.name).join(', ') || 'ninguno'})`);
      const lying = g.expanded.groups.filter(x => { const m = /^(\d+) de ([\d.]+)$/.exec(x.more || ''); return x.more && (!m || +m[1] !== x.rows); });
      const railed = g.expanded.groups.filter(x => x.tiles);
      ok(lying.length === 0 && g.expanded.groups.every(x => !x.deadCap) && railed.every(x => !x.more),
        `C6 ${theme} ${n} estantes: what is not shown is offered, not captioned — and a rail shows the whole shelf, so ${railed.length} of ${g.expanded.groups.length} bloques have nothing left to page (${g.expanded.groups.map(x => x.more || 'todo').join(' · ')})`);
      /* and the zone bar is earned by LENGTH, not granted to every rail: 024 is untouched under it. */
      const wrong = railed.filter(x => x.zoneBar !== (x.slots > 30 ? 1 : 0));
      ok(wrong.length === 0,
        `C6 ${theme} ${n} estantes: the zone bar only appears past the length you can fling end-to-end — 024-A is untouched under it (${railed.map(x => x.slots + ':' + (x.zoneBar ? 'barra' : 'sin barra')).join(' · ')})`);
      /* the re-based E5: a query answers in rows that carry what the headings used to carry */
      ok(g.searched.headings === 0 && g.searched.label === 'Resultados' && g.searched.hits.length >= 1,
        `C6 ${theme} ${n} estantes: a query answers in a flat result list, not in ${g.collapsed.groups.length} headings (${g.searched.headings} headings, “${g.searched.label}” ×${g.searched.count})`);
      ok(g.searched.hits.every(h => /Estante/.test(h.sub)),
        `C6 ${theme} ${n} estantes: and every hit names its estante on the row itself (${g.searched.hits.map(h => h.name + ' ⟨' + h.sub + '⟩').join(' · ')})`);
      ok(g.searched.h <= g.collapsed.h && g.searched.screens <= 1.01,
        `C6 ${theme} ${n} estantes: which fits the answer in one screen (${g.searched.h}px = ${g.searched.screens} screens, vs ${g.collapsed.h}px shut${n === '12' ? ' — R7b measured 1467px = 1.98 screens here' : ''})`);
      ok(g.searched.hits.every(h => h.top + h.h <= g.searched.screen || h.top + h.h <= 740),
        `C6 ${theme} ${n} estantes: the hit needs no scrolling (bottom ${g.searched.hits.map(h => h.top + h.h).join('/')} of ${g.collapsed.screen}px)`);
      ok(g.searched.fieldSurvived, `C6 ${theme} ${n} estantes: and the search field is still the same node afterwards (C5 holds through the new region)`);
    }

    /* --- C7 the chip row, and the control Estantes no longer has ---------------------------------- */
    /* 065 R10: still zero on the PAGE. The zone bar is a chip row, but it belongs to an OPEN estante and
       navigates inside that estante's rail — it never changes what the page shows, which is the thing
       R7b retired. Measured with every estante shut, which is what the page opens as. */
    ok(B.noSwitch.segs === 0 && B.noSwitch.chips === 0 && B.noSwitch.vista === 0 && B.noSwitch.radios === 0,
      `C7 ${theme}: Estantes has no view control of any kind (.seg ${B.noSwitch.segs}, .chip ${B.noSwitch.chips}, radios ${B.noSwitch.radios}, v-vista ${B.noSwitch.vista})`);
    ok(B.noSwitch.searches === 1 && B.noSwitch.shelves === B.noSwitch.ofShelves,
      `C7 ${theme}: one page, one search, every estante reachable on it (${B.noSwitch.searches} search, ${B.noSwitch.shelves}/${B.noSwitch.ofShelves} bloques)`);
    for (const c of B.filterChips) {
      ok(c.bw === 1 && c.vsPage >= 3 && c.vsFill >= 3,
        `C7 ${theme}: “${c.text}”${c.on ? ' (elegida)' : ''} has a real 1px boundary over 3:1 (${c.vsPage}:1 vs la página, ${c.vsFill}:1 vs su propio relleno)`);
      ok(c.radius === '8px' && c.hit >= 44,
        `C7 ${theme}: “${c.text}” is on the admin's 8px radius with a 44px hit area (${c.radius}, ${c.h}px drawn / ${c.hit}px tocable)`);
    }
    const sel = B.filterChips.filter(c => c.on);
    ok(sel.length === 1 && sel[0].tick && sel[0].tickVsFill >= 3 && sel[0].fw === 600,
      `C7 ${theme}: the chosen chip is marked by a glyph, not by colour alone (✓ a ${sel[0] && sel[0].tickVsFill}:1, ${sel[0] && sel[0].fw})`);
    ok(B.filterChips.length >= 4,
      `C7 ${theme}: the component still has its instances after the view switch went (${B.filterChips.length} chips on Juegos)`);
    const shapes = [...new Set(B.stack.map(s => s.split(':')[1]))];
    ok(shapes.length === 1 && shapes[0] === '8px',
      `C7 ${theme}: and the whole control stack is one shape (${B.stack.join(' · ')})`);
  }
  await p.evaluate(() => delete document.documentElement.dataset.theme);
  await p.evaluate(() => { Object.assign(V, seed062(true), { ed: null, ordering: null, memQ: '', listaQ: '' }); resetGrps(); go('panel'); });
  await p.waitForTimeout(240);

  /* ================= P. ONE Estantes page (065 R8) =================
     The developer: "the buttons recorrido and contenido is too complex. Is better a collapsable list
     of games on a estante and then games to add? also from the list I should be able to remove it and
     sort inside a estante?" · "the #1 action is to look where is the game(estante) and together to
     which games(in middle of which games)" · "the positional should be first but also could be
     expandable with the rest of information".
     THE PREMISE, asserted rather than assumed: the order of the games on an estante IS their physical
     left-to-right order, so the zone is an index read back in words and Ordenar moves a real box. */
  for (const theme of ['light', 'dark']) {
    await p.evaluate(t => t === 'dark' ? document.documentElement.dataset.theme = 'dark' : delete document.documentElement.dataset.theme, theme);
    const E = await p.evaluate(() => window.__r8());
    const T = theme;

    /* --- P1 one page, and the finding job leads it ----------------------------------------------- */
    ok(E.page.searchTop < E.page.firstShelfTop && E.page.searchTop <= 200,
      `P1 ${T}: the search is the page's first control (título ${E.page.titleTop} → progreso ${E.page.progTop} → buscar ${E.page.searchTop} → primer estante ${E.page.firstShelfTop}; R7 put the field at 227 on a second view and the first estante at 368)`);
    ok(E.page.label === 'Estantes del club',
      `P1 ${T}: the list of estantes names itself (“${E.page.label}”)`);
    ok(E.page.overflowX <= 0 && E.page.screens <= 1.1,
      `P1 ${T}: and the whole page is ${E.page.h}px = ${E.page.screens} screens with no sideways scroll (${E.page.overflowX}px)`);

    /* --- P1 (cont.) "Nuevo estante" is a page-level action in a sheet, out of the way -------------
       065 R10 RE-POINTS THIS ONE LEVEL DOWN, and the developer's complaint is why: "those are too big
       and kill balance". R8 made it Secundaria, which in 064's system means a 1px outline — so the
       Estantes page carried THREE equal outlines and no Principal at all. R10 rule 2 makes a
       page-level action Terciaria: it sits under content it does not belong to, so it is text. The
       claim it keeps is the one that mattered (it is not Principal, it is 44px, it opens a dialog and
       it is not a form in the page body); what changes is that it may not be outlined either. */
    ok(E.page.newShelf && /\btbtn\b/.test(E.page.newShelf.cls) && !/b-sec|b-pri|obtn/.test(E.page.newShelf.cls)
      && E.page.newShelf.pop === 'dialog' && E.page.newShelf.h === 44,
      `P1 ${T}: Nuevo estante is a Terciaria text action and opens a dialog (${E.page.newShelf && E.page.newShelf.cls}, ${E.page.newShelf && E.page.newShelf.h}px, haspopup ${E.page.newShelf && E.page.newShelf.pop})`);
    ok(E.page.newShelf.form === 0 && !E.page.newShelf.inBody && E.page.addForms === 0
      && E.page.newShelf.top > E.page.firstShelfTop,
      `P1 ${T}: and it is not a form in the page body any more (forms on the page ${E.page.addForms}; the control sits at ${E.page.newShelf.top}, past the estantes at ${E.page.firstShelfTop} — R7's form sat at 227, above them)`);

    /* --- P2 an expanded estante shows its real contents, in the shelf's own order -----------------
       065 R10: the carrier is the rail's tiles. The rule is untouched — an open estante shows the
       shelf's real contents in the shelf's own order — and the second half CHANGES SHAPE with its
       reason: a rail shows the whole shelf, so there is nothing left to page and no "Mostrar más"
       caption to keep honest. What it cannot NAME is offered by the hatched bands instead (X8). */
    ok(E.open.rows.length === 0 && E.open.tiles.length > 0 && E.open.tiles.join('|') === E.open.order.join('|'),
      `P2 ${T}: an open estante shows its games in the shelf's own order, as the rail (${E.open.tiles.join(' → ')}; filas verticales ${E.open.rows.length})`);
    ok(E.open.tileSlots.every((v, i) => i === 0 || v > E.open.tileSlots[i - 1]) && E.open.mores === 0 && !E.open.cap,
      `P2 ${T}: left-to-right on screen is left-to-right on the wood (slots ${E.open.tileSlots.join(',')}), and the whole shelf is there — nothing to page (${E.open.mores} “Mostrar más”, count line “${E.open.count}”)`);
    const strip = E.open.acts;
    ok(strip.length === 2 && strip[0].act === 'v-add-mode' && strip[1].act === 'v-shelf-sheet',
      `P2 ${T}: an open estante carries the two jobs the retired screen owned (${strip.map(a => a.act + '“' + a.label + '”').join(' · ')})`);
    ok(strip.every(a => a.h >= 44) && Math.abs(strip[1].right - strip[1].edge) <= 12,
      `P2 ${T}: both are 44px and the strip ends on the row's content edge (${strip.map(a => a.h + 'px').join('/')}, ${strip[1].right} vs ${strip[1].edge})`);

    /* --- P5 the position inside an estante, and what a search result says ------------------------
       065 R9 re-pointed the first of these when its census measured R8's claim out of existence: on
       all four estantes every rendered row carried the IDENTICAL zone word. 065 R10 re-points it
       AGAIN, and this time the subject is gone rather than changed — the developer promoted the rail,
       so there are no rows inside an estante to restate anything. The rule becomes the stronger claim
       the rail is making: NOTHING inside an open estante says the position in words, because the
       geometry says it, and the only place it is still said is where a screen reader can hear it. */
    ok(E.open.zoneWords === 0,
      `P5 ${T}: inside an open estante nothing restates the position in words — the rail's order IS the position (${E.open.zoneWords} zone words over ${E.open.tiles.length} cajas rendered)`);
    ok(E.open.labels.every(l => /caja \d+ de \d+$/.test(l || '')) && /de izquierda a derecha/.test(E.open.railGroupLabel || ''),
      `P5 ${T}: but every tile SAYS it to a screen reader, which has no geometry to read (“${E.open.labels[0]}” … grupo “${E.open.railGroupLabel}”)`);
    ok(E.open.repeatsShelfName === 0,
      `P5 ${T}: and inside the estante nothing repeats the estante's name (${E.open.repeatsShelfName} of ${E.open.tiles.length} mention “${E.open.shelfName}”)`);
    ok(E.panel.acts.length === 2 && /v-rm-shelf/.test(E.panel.acts.join()) && E.panel.name === E.open.tiles[0] && E.panel.pressed === 'true',
      `P5 ${T}: a marked tile opens the two jobs a row used to carry, remove included (“${E.panel.name}”: ${E.panel.acts.join(' · ')})`);
    ok(E.panel.onlyOne === 1,
      `P5 ${T}: and only one box is ever marked (${E.panel.onlyOne} tile marcada tras tocar otra)`);
    ok(/caja \d+ de \d+$/.test(E.exp.marked || '') && E.exp.centred && E.exp.neighbours.left >= 2 && E.exp.neighbours.right >= 2,
      `P5 ${T}: expanding a search result reveals the neighbours — as the rail, scrolled to the box and marked (${E.exp.neighbours.left} a la izquierda, ${E.exp.neighbours.right} a la derecha: ${E.exp.neighbours.names.join(' | ')})`);
    /* the INVERSION, stated: R8 asserted the expansion starts on the row's own 68px text column. A rail
       is full-bleed by definition, so it reaches back out to the page edge instead — the one place a
       -68px margin appears in this admin, and the rail recipe asserting itself over the indent. */
    ok(Math.abs(E.exp.left - E.exp.pageLeft) <= 0.5 && E.exp.left < E.exp.nameLeft,
      `P5 ${T}: and a rail inside an expansion is full-bleed, not indented to the row's text column (riel en ${E.exp.left} = borde de página ${E.exp.pageLeft}, contra la columna de texto en ${E.exp.nameLeft})`);
    ok(E.exp.aria === 'true' && E.exp.onlyOne === 1 && E.exp.bar === 0,
      `P5 ${T}: aria-expanded is on the row, one expansion at a time, and no zone bar on an answer you already have (${E.exp.aria}, ${E.exp.onlyOne} expansión, ${E.exp.bar} barras)`);
    ok(E.exp.acts.length === 2 && /v-rm-shelf/.test(E.exp.acts.join()),
      `P5 ${T}: the row's own actions are there, remove included (${E.exp.acts.join(' · ')})`);
    /* THE COMBINATION R10 SHIPS, and the regression it avoids: R9 measured B's weak point as the
       collapsed row, which had dropped the zone to make the rail the only position channel — so
       before you tapped you knew LESS than in A. The shipped page keeps both. */
    ok(/Más a la izquierda|Al medio|Más a la derecha/.test(E.exp.collapsedSub) && /Estante/.test(E.exp.collapsedSub),
      `P5 ${T}: and the collapsed search row still says which end to walk to before you tap — the half R9 measured B throwing away (“${E.exp.collapsedSub}”)`);
    ok(E.search.rows.every(r => /Sin ubicar/.test(r.sub) || /Estante/.test(r.sub)),
      `P5 ${T}: in a search result the estante's name IS on the row (${E.search.rows.slice(0, 3).map(r => r.name + ' ⟨' + r.sub + '⟩').join(' · ')})`);
    ok(E.search.rows.every(r => r.lines === 1) && E.search.groups === 0,
      `P5 ${T}: on one line each (${E.search.n} results, row heights ${E.search.heights.join('/')}px — zona · estante · año wrapped 6 of 13 and cost 4 heights)`);

    /* --- P3 remove works from that surface, and the ledger follows -------------------------------
       065 R10: driven from a marked tile's panel instead of a row's expansion. Every claim is the
       same one and every number is measured the same way. */
    ok(E.remove.after.count === E.remove.before.count - 1 && E.remove.after.unplaced === E.remove.before.unplaced + 1,
      `P3 ${T}: quitar “${E.remove.name}” del estante moves it to Sin ubicar (estante ${E.remove.before.count} → ${E.remove.after.count}, sin ubicar ${E.remove.before.unplaced} → ${E.remove.after.unplaced})`);
    ok(E.remove.after.order.length === E.remove.before.order.length - 1 && !E.remove.after.order.includes(E.remove.before.order.find(x => x != null && !E.remove.after.order.includes(x))),
      `P3 ${T}: and the slot closes up behind it (${E.remove.before.order.length} → ${E.remove.after.order.length} slots)`);
    ok(E.remove.after.sum === E.remove.after.placed && String(E.remove.after.badge) === String(E.remove.after.unplaced),
      `P3 ${T}: every counter agrees afterwards (Σestantes ${E.remove.after.sum} = ubicados ${E.remove.after.placed}, badge “${E.remove.after.badge}” = ${E.remove.after.unplaced}; “${E.remove.after.prog}”)`);
    ok(E.remove.sameOrder && E.remove.undone.count === E.remove.before.count,
      `P3 ${T}: and Deshacer puts the box back where it was (“${E.remove.after.snack}” → ${E.remove.undone.count}, orden idéntico ${E.remove.sameOrder})`);

    /* --- P4 sort works from that surface, one physical slot at a time ----------------------------
       065 R10: driven from the marked tile's ← / →. Same rule, and R9's one clean victory for the rail
       finally lands — the glyph and the label now point the same way, which is why R9 left it as an
       open item instead of half-changing a vertical list. */
    ok(E.sort.orderChanged && E.sort.onlyTwoMoved && E.sort.movedTo === E.sort.at - 1,
      `P4 ${T}: ← moves the box one slot left and nothing else moves (índice ${E.sort.at} → ${E.sort.movedTo}, ${E.sort.onlyTwoMoved ? 2 : 'más de 2'} slots cambiados)`);
    ok(E.sort.nowAt === E.sort.swappedWith,
      `P4 ${T}: it swapped with the slot that was there (${E.sort.swappedWith} ahora en ${E.sort.at})`);
    ok(E.sort.arrowLabels.length === 2 && /a la izquierda$/.test(E.sort.arrowLabels[0]) && /a la derecha$/.test(E.sort.arrowLabels[1]),
      `P4 ${T}: the glyph and the label finally point the same way — the way the box really moves (${E.sort.arrowLabels.join(' · ')}); R8's ↑ / ↓ pointed a way no shelf has`);
    ok(E.sort.markFollowed.slot === E.sort.at - 1 && E.sort.markFollowed.name === E.sort.movedName,
      `P4 ${T}: and the mark follows the box, so the panel keeps naming the game you moved (“${E.sort.markFollowed.name}” en slot ${E.sort.markFollowed.slot})`);
    const arrows = E.sort.ends, arrLen = arrows.length ? arrows[0].len : 0;
    const arrBad = arrows.filter(x => x.left !== x.wantLeft || x.right !== x.wantRight);
    ok(arrows.length > 0 && arrBad.length === 0,
      `P4 ${T}: an arrow stops at the shelf's real end, not at the last named box (${arrows.length} cajas con nombre en 3 estantes — una con su corrida al inicio, una al medio y una al final; deshabilitadas ←/→ ${arrows.map(x => 's' + x.sid + '#' + x.i + (x.left ? 'L' : '-') + (x.right ? 'R' : '-')).join(' ')})`);
    ok(/orden real del estante/.test(E.sort.hint) || /caja/.test(E.sort.hint),
      `P4 ${T}: and the hint says the box moves too (“${E.sort.hint}”)`);
    ok(/^Listo/.test(E.sort.listo || '') && /b-pri/.test(E.sort.listo || ''),
      `P4 ${T}: Ordenar mode ends with the admin's own Principal “Listo” (${E.sort.listo})`);

    /* --- P6 the zone is the derivation, not a hard-coded case ------------------------------------- */
    const zb = E.zones.filter(z => !z.monotone || !z.inRange
      || (z.n >= 3 && (z.first !== 'Más a la izquierda' || z.last !== 'Más a la derecha'))
      || (z.n >= 3 && (Math.abs(z.cut1 - z.third) > 1 || Math.abs(z.cut2 - z.twoThirds) > 1)));
    ok(zb.length === 0,
      `P6 ${T}: the zone is monotone in the index and cuts on thirds at every shelf length (${E.zones.map(z => z.n + ':' + z.bands.join('/')).join(' · ')})`);
    ok(E.zones.filter(z => z.n >= 3).every(z => z.distinct === 3),
      `P6 ${T}: three zones, all three reachable, one vocabulary at every length (${E.zones.map(z => z.n + ':' + z.distinct).join(' · ')})`);

    /* --- P8 everything the retired screen did, from this one page --------------------------------- */
    ok(E.add.mode === 1 && E.add.rows > 0 && E.add.acts.join() === 'Listo',
      `P8 ${T}: an estante's "Agregar juegos" is a mode on the estante, not a screen (${E.add.rows} filas sin ubicar, salida “${E.add.acts.join()}”)`);
    ok(E.add.progVisible && E.add.meter,
      `P8 ${T}: and the progress line it is measured by stays on screen (meter ${E.add.meter}, visible ${E.add.progVisible}) — a sheet would put a 38% scrim over it`);
    ok(E.add.rowH === E.open.acts && false || (E.add.rowH >= 60 && E.add.slot === 40),
      `P8 ${T}: the add list uses the page's own row anatomy (${E.add.rowH}px row, ${E.add.slot}px thumb — a sheet's .dlink is 48px with a 28px slot and no thumbnail)`);
    ok(E.add.after.grew === 1 && E.add.after.unplacedFell === 1 && E.add.after.wentToEnd === E.add.after.name,
      `P8 ${T}: ubicar puts the box at the far right end and says so (“${E.add.after.snack}”; último del estante: ${E.add.after.wentToEnd})`);
    ok(E.add.after.sum === E.add.after.placed && String(E.add.after.badge) === String(E.add.after.unplaced),
      `P8 ${T}: the counters follow it (Σ ${E.add.after.sum} = ${E.add.after.placed}, badge “${E.add.after.badge}” = ${E.add.after.unplaced})`);
    ok(E.add.after.zoneOfNew === 'Más a la derecha',
      `P8 ${T}: and the game it just placed reads its own position back (“${E.add.after.zoneOfNew}”)`);
    ok(E.add.undone.count === E.add.after.count - 1,
      `P8 ${T}: Deshacer takes it off again (${E.add.after.count} → ${E.add.undone.count})`);
    ok(/final de/.test(E.add.hint),
      `P8 ${T}: the mode's hint says where the box goes (“${E.add.hint}”)`);

    /* --- P10 fixture honesty: a zone and a pair of neighbours need the whole order to exist ------- */
    for (const n of ['4', '12']) {
      const F = E.fixture[n];
      ok(F.sum === F.placed && F.placed + F.unplaced === F.total,
        `P10 ${T} ${n} estantes: Σ of the shelves' ORDER arrays is the placed count (${F.sum} = ${F.placed}, +${F.unplaced} sin ubicar = ${F.total})`);
      ok(F.shelves.every(s => s.count > 0 && s.named > 0 && s.contiguous),
        `P10 ${T} ${n} estantes: every shelf's order is materialised and its named games sit in one run (${F.shelves.map(s => s.named + '/' + s.count + '@' + (s.run || []).join('-')).join(' · ')})`);
      const liars = F.shelves.flatMap(s => s.claims.filter(c => !c.honest).map(c => s.name + ': ' + c.line));
      ok(liars.length === 0,
        `P10 ${T} ${n} estantes: no row claims a neighbour it does not have (${F.shelves.reduce((a, s) => a + s.claims.length, 0)} líneas revisadas${liars.length ? ': ' + liars.join(' | ') : ''})`);
      const kinds = [...new Set(F.shelves.flatMap(s => s.claims.map(c => c.line.replace(/ .*/, ''))))].sort();
      ok(kinds.length >= 3,
        `P10 ${T} ${n} estantes: and the fixture exercises every shape of the answer (${kinds.join(' · ')})`);
    }
  }
  await p.evaluate(() => delete document.documentElement.dataset.theme);
  await p.evaluate(() => { Object.assign(V, seed062(true), { ed: null, ordering: null, memQ: '', listaQ: '' }); resetGrps(); go('panel'); });
  await p.waitForTimeout(240);

  /* --- P11 the retired control and the retired screen, asserted rather than assumed ------------- */
  const retired = await p.evaluate(() => ({
    screen: typeof SCREENS.asignar,
    body: (() => { try { S.screen = 'asignar'; adminBody(); return 'rendered'; } catch (e) { S.screen = 'estantes'; return 'gone'; } })(),
    asgBody: typeof window.asgBody, asgQ: 'asgQ' in V, vista: 'vista' in V,
    walk: (typeof WALK !== 'undefined' ? WALK.map(w => w.k) : []).filter(k => k === 'asignar').length,
    qreg: Object.keys(QREG).join(','),
  }));
  ok(retired.screen === 'undefined' && retired.body === 'gone' && retired.walk === 0,
    `P11 the Asignar screen is retired, not hidden (SCREENS.asignar ${retired.screen}, adminBody ${retired.body}, walk stops ${retired.walk})`);
  ok(retired.asgBody === 'undefined' && !retired.asgQ && !retired.vista,
    `P11 and nothing of it is left behind (asgBody ${retired.asgBody}, V.asgQ ${retired.asgQ}, V.vista ${retired.vista}, QREG ${retired.qreg})`);

  /* --- P7 "Nuevo estante": secondary, in a sheet, validating inline, committing from the keyboard ---
     Driven end to end, exactly the way R7b drove the rename sheet, because this is the second form in
     a sheet in the admin and the sheet-action rule is what it has to obey. */
  const nsForm = [];
  for (const [what, value, expect] of [['vacío', '', 'Poné un nombre.'], ['duplicado', 'Estante C — fiesta', 'Ya hay un estante con ese nombre.']]) {
    await p.evaluate(() => { Object.assign(V, seed062(true)); V.listaQ = ''; V.ordering = null; resetGrps(); go('estantes'); });
    await p.waitForTimeout(440);
    const n0 = await p.evaluate(() => V.shelves.length);
    await p.evaluate(() => document.querySelector('[data-act="v-new-shelf"]').click());
    await p.waitForTimeout(420);
    await p.evaluate(v => { const i = document.getElementById('shelf-new'); i.focus(); i.value = v; i.dispatchEvent(new Event('input', { bubbles: true })); }, value);
    await p.waitForTimeout(140);
    await p.keyboard.press('Enter');
    await p.waitForTimeout(400);
    nsForm.push([what, expect, await p.evaluate(n0 => ({ open: !!document.querySelector('.sheet.open'),
      err: document.querySelector('#sheet-act .ferr')?.textContent.trim() || '',
      invalid: !!document.getElementById('shelf-new')?.classList.contains('invalid'),
      focus: document.activeElement?.id, made: V.shelves.length - n0 }), n0)]);
    await p.evaluate(() => closeAll());
    await p.waitForTimeout(220);
  }
  for (const [what, expect, st] of nsForm)
    ok(st.open && st.err === expect && st.invalid && st.focus === 'shelf-new' && st.made === 0,
      `P7 a ${what} name reports in the Nuevo estante sheet without closing it (“${st.err}”, abierta ${st.open}, foco ${st.focus}, estantes creados ${st.made})`);
  for (const [how, commit] of [['con Enter', null], ['tocando la fila', '[...document.querySelectorAll("#sheet-act .dlink")].find(r => /Crear/.test(r.textContent)).click()']]) {
    await p.evaluate(() => { Object.assign(V, seed062(true)); V.listaQ = ''; V.ordering = null; resetGrps(); go('estantes'); });
    await p.waitForTimeout(440);
    const n0 = await p.evaluate(() => V.shelves.length);
    await p.evaluate(() => document.querySelector('[data-act="v-new-shelf"]').click());
    await p.waitForTimeout(420);
    await p.evaluate(() => { const i = document.getElementById('shelf-new'); i.focus(); i.value = 'Estante Z — probado'; i.dispatchEvent(new Event('input', { bubbles: true })); });
    await p.waitForTimeout(140);
    if (commit) await p.evaluate(c => (0, eval)(c), commit); else await p.keyboard.press('Enter');
    await p.waitForTimeout(650);
    const st = await p.evaluate(n0 => ({ open: !!document.querySelector('.sheet.open'), made: V.shelves.length - n0,
      once: V.shelves.filter(s => s.name === 'Estante Z — probado').length,
      last: V.shelves[V.shelves.length - 1].name, order: JSON.stringify(V.order[V.shelves[V.shelves.length - 1].id]),
      snack: document.querySelector('#snack')?.textContent.trim(),
      sum: V.shelves.reduce((a, s) => a + shelfCount(s), 0), placed: placedN() }), n0);
    ok(!st.open && st.made === 1 && st.once === 1 && st.last === 'Estante Z — probado' && /creado/i.test(st.snack || ''),
      `P7 Nuevo estante commits ${how} exactly once, at the end of the recorrido (“${st.last}” ×${st.once}, hoja abierta ${st.open}, “${st.snack}”)`);
    ok(st.order === '[]' && st.sum === st.placed,
      `P7 and a brand-new estante starts with a real, empty order (order ${st.order}, Σ ${st.sum} = ubicados ${st.placed})`);
  }
  await p.evaluate(() => { Object.assign(V, seed062(true), { ed: null, ordering: null, memQ: '', listaQ: '' }); resetGrps(); closeAll(); go('panel'); });
  await p.waitForTimeout(240);

  /* --- P9 a status marker inside a meta item is actually DRAWN -----------------------------------
     Round 8 moved "Sin ubicar" inside a .mi so the separator logic would give it its "·", and that
     turned .dot from a flex item of .gsub into an inline non-replaced box, where width and height do
     not apply: it measured 0px wide and no eye would have caught it. */
  for (const theme of ['light', 'dark']) {
    await p.evaluate(t => t === 'dark' ? document.documentElement.dataset.theme = 'dark' : delete document.documentElement.dataset.theme, theme);
    await p.evaluate(() => { V.listaQ = ''; V.ordering = null; resetGrps(); go('estantes'); });
    await p.waitForTimeout(440);
    await p.evaluate(() => { const f = document.getElementById('lista-q'); f.focus(); f.value = 'ar'; f.dispatchEvent(new Event('input', { bubbles: true })); });
    await p.waitForTimeout(460);
    const dots = await p.evaluate(() => [...document.querySelectorAll('#main .gsub .dot')].map(d => {
      const r = d.getBoundingClientRect(), cs = getComputedStyle(d);
      return { w: +r.width.toFixed(1), h: +r.height.toFixed(1), display: cs.display,
        gap: (() => { const n = d.nextElementSibling; return n ? +(n.getBoundingClientRect().left - r.right).toFixed(1) : null; })() };
    }));
    ok(dots.length > 0 && dots.every(d => d.w >= 6 && d.h >= 6 && Math.abs(d.w - d.h) <= 0.5),
      `P9 ${theme}: every status dot on a meta line is really drawn at its declared size (${dots.map(d => d.w + '×' + d.h + ' ' + d.display).join(' · ') || 'none'})`);
    ok(dots.every(d => d.gap === null || d.gap >= 4),
      `P9 ${theme}: and it keeps the meta line's own gap off its word (${dots.map(d => d.gap).join('/')}px)`);
    await p.evaluate(() => { V.listaQ = ''; resetGrps(); patch(); });
    await p.waitForTimeout(240);
  }
  await p.evaluate(() => delete document.documentElement.dataset.theme);
  await p.evaluate(() => go('panel'));
  await p.waitForTimeout(240);

  /* ================= ROUNDS 9/10: the estante IS a rail (022–026's carousel, in the admin) =========
     Developer, R9: "what if we use carousel(horizontal scrolable) to represent that physical position,
     maybe been inspired by Apple iBooks?" — R9 measured THE RAIL AS THE LOSER over 162 boxes and
     shipped the list. Developer, R10: "For estantes, I want option B(riel). remove the another
     variants." That is a DEVELOPER OVERRIDE OF A MEASURED VERDICT, recorded the way round 6's "copia"
     reversal was: R9's numbers stay in the README exactly as measured, and none of them is rewritten
     to make the rail look like it won.
     WHAT THAT DOES TO THIS GROUP: every assertion keeps its rule and most change subject, because the
     numbers R9 charged AGAINST the rail are now the problems this page owns.
       X1  "three variants render" → one page ships, and nothing of A or C is left in the file.
       X2  "024 holds, and that is why the rail loses" → 024 holds ON THE RAIL, and the fade's three
           states become the scoped exception's justification: the zone bar reaches the three positions
           the fade can only distinguish, and only past the length you can fling end-to-end.
       X3  A/B/C heights → the shipped estante's height, against R9's recorded A = 493px.
       X4  27 presses to the middle → still computed, and now the baseline the bar is measured against
           (1 tap), with a scrubber built, measured and rejected beside it.
       X6  "tab stops A vs B vs C" → the shipped page's stops, rail + bar.
       X9  "the zone is dropped inside, kept in search" → the same census, plus the word's second job.
       X10 "the rail flow works and still loses" → the flow works and keeps the half B had dropped.
     Each re-pointing says so where it lands, and X5/X7/X8 are untouched. */
  for (const theme of ['light', 'dark']) {
    await p.evaluate(t => t === 'dark' ? document.documentElement.dataset.theme = 'dark' : delete document.documentElement.dataset.theme, theme);
    const R = await p.evaluate(() => window.__r9());
    const T = theme;

    /* --- X1 ONE page ships, and the losers are deleted rather than hidden ----------------------- */
    ok(R.D.tiles > 0 && R.D.rows === 0 && R.D.railH > 0,
      `X1 ${T}: an open estante IS the rail — no vertical list of its games at all (${R.D.tiles} tiles + ${R.D.bands} franjas, ${R.D.rows} filas, riel ${R.D.railH}px)`);
    ok(R.gone.est === 0 && R.gone.map === 0 && R.gone.switch === 0,
      `X1 ${T}: and R9's A and C are deleted, not parked behind a switch — build.js throws on a trace of either (V.est ${R.gone.est}, .map ${R.gone.map}, data-est ${R.gone.switch})`);

    /* --- X2 THE 024 VERDICT, AND THE EXCEPTION R10 OWES IT. 024-A ruled a rail carries no position or
       pagination indicator — edge-fade only — for a public rail of 8–10 cards where either end is one
       fling away. R9 held it and measured what holding it costs at 162 boxes: the fade is two booleans,
       so it tells apart THREE positions, and 39 of 41 offsets across the whole range are the same one.
       R10 ships the rail, so that cost is real, and the exception is argued rather than taken:
         · 024's PREMISE IS FALSE HERE. Its own README says "this app's shelves are shorter (8-10
           cards) where 'how far through this row am I' is a more answerable question". At 162 the fade
           degenerates from "where am I" to "can I scroll".
         · THE EXCEPTION IS SCOPED TO LENGTH, not to the admin by fiat: nothing is added under
           ZONE_NAV_MIN boxes, which is every rail the catalogue ships. Asserted in C6.
         · THE RAIL ITSELF IS UNTOUCHED — no indicator inside it, no per-tile ordinal. The bar is a
           SIBLING with three states, the same three the fade can distinguish and cannot reach.
         · WHAT WOULD GENERALISE IT BACK: a rail short enough to fling end-to-end needs no bar, so if
           the catalogue ever grows a shelf past ~30 cards this is the control to reach for — and it
           would still be three words and not a progress bar, which at this length is 1px of fill per
           2 boxes. --- */
    ok(R.D.railIndicators === 0 && R.D.ordinals === 0,
      `X2 ${T}: 024-A holds on the rail itself — no position or pagination indicator inside it, no tile ordinal (indicadores ${R.D.railIndicators}, ordinales ${R.D.ordinals})`);
    ok(R.fade.n === 3 && R.fade.middleAllSame,
      `X2 ${T}: and the exception is earned by that measurement — the edge-fade distinguishes ${R.fade.n} positions over ${R.fade.slots} cajas and ${R.fade.range}px of range (${R.fade.states.join(' ')}; ${R.fade.census.LR} of ${R.fade.samples} offsets are the same single state, todo el medio idéntico ${R.fade.middleAllSame})`);
    ok(R.bar && R.bar.n === 3 && !R.bar.inRail && R.bar.aboveRail,
      `X2 ${T}: the zone bar is a sibling OUTSIDE the rail with exactly three states — the fade's own three, made reachable (${R.bar.n} destinos, dentro del riel ${R.bar.inRail}, sobre el riel ${R.bar.aboveRail})`);

    /* --- X3 cost, re-pointed onto the shipped page. R9's constants: A (the list) 493px, B (the rail)
       317px, C (rail + list) 553px, over Estante D's 162 boxes at 420px. The rail is the cheapest of
       the three and R10 adds the zone bar to it, so what has to stay true is that the page it replaced
       is still the expensive one — otherwise the override bought nothing. --- */
    ok(R.D.openH < 493 && R.D.openH > R.D.railH,
      `X3 ${T}: an open Estante D costs ${R.D.openH}px, against R9's measured 493px for the list it replaced and 553px for the rail-plus-list (riel ${R.D.railH}px, barra de zonas ${R.bar.h}px)`);
    ok(R.D.tiles + R.D.bands <= 12 && R.set.fullTiles >= 3,
      `X3 ${T}: and it shows ${R.set.fullTiles} whole boxes at once with no paging, where R9's list showed 5 rows and paged 8 at a time (${R.D.tiles} tiles + ${R.D.bands} franjas cubren las ${R.mid.slots} cajas)`);

    /* --- X4 THE PROBLEM THE OVERRIDE MAKES DUE, AND THE ANSWER. R9 measured the trip to the middle of
       162 boxes as 27 arrow presses on a pointer and 8–15 flings on a phone, and called the rail "a
       good DISPLAY of a shelf and a bad NAVIGATOR of one". R10 ships it, so X4 stops being the case
       against the rail and becomes the baseline the zone bar is measured against — same computation,
       unchanged, plus the bar DRIVEN (not derived) and the worst case over every slot, so the bar
       cannot be credited only with the one target it was built to hit. --- */
    X_PRESSES_PHONE = R.mid.presses;
    ok(R.mid.presses >= 25 && R.mid.cardsPerPress > 2.5 && R.mid.cardsPerPress < 3.5,
      `X4 ${T}: with arrows alone the middle of ${R.mid.slots} cajas is still ${R.mid.presses} presses — ${R.mid.pxToMiddle}px at ${R.mid.perPress}px (${R.mid.cardsPerPress} cajas) each, over a ${R.mid.scrollW}px rail (R9's number, recomputed)`);
    ok(R.mid.barTaps === 1 && R.mid.barOff === 0,
      `X4 ${T}: the zone bar makes it ONE tap — "Medio" lands on caja ${R.mid.barLanded + 1} de ${R.mid.slots}, exactly the middle box (${R.mid.barOff} de diferencia), and the readout follows: ${R.mid.barReadout}`);
    ok(R.mid.worstTotal < R.mid.presses && R.mid.worstTotal <= 16,
      `X4 ${T}: and the worst box on the shelf is ${R.mid.worstTotal} (1 tap + ${R.mid.worstPresses} presses, caja ${R.mid.worstSlot + 1}) against ${R.mid.presses} — three anchors leave ${R.scrub.anchorGap}-box gaps, which is why search at 2 taps is still the way to a NAMED box`);
    /* THE SCRUBBER, BUILT AND MEASURED RATHER THAN WAVED OFF — and this is the place the round's own
       hypothesis was WRONG. R9 wrote that past the fling length a rail "needs a scrubber with a grab
       handle, which is what Apple itself reaches for once a library stops fitting a shelf", and the
       guess going in was that three jump targets would beat it outright. They do not, on precision: a
       scrubber lands within half a fingertip and finishes in a few presses, where three anchors leave
       gaps half an anchor-spacing wide. Both are ONE GESTURE to the middle, which was the named
       problem, so the bar is chosen on everything else, in numbers:
         · the handle has to be inflated to the 44px touch floor to be grabbable, so it draws a
           viewport SIX TIMES bigger than the one it stands for — a position indicator that lies;
         · it is a drag inside a horizontal scroller inside a vertical page, i.e. it re-introduces the
           one gesture conflict X7 measures as absent;
         · for AT it is a role="slider" with 162 values against three named destinations;
         · it costs a new component and a new vocabulary, where the bar costs neither — the three words
           already existed and the census had just retired them from describing.
       Asserted in the direction that is TRUE, so a later round cannot re-argue it as a taste. */
    ok(R.scrub.handleInflation >= 3 && R.scrub.worstTotal < R.mid.worstTotal,
      `X4 ${T}: and a scrubber is genuinely FINER than the bar on an arbitrary box — ${R.scrub.worstTotal} gestures (1 drag landing within ±${R.scrub.resolution} cajas, then ${R.scrub.pressesAfter} presses) against the bar's ${R.mid.worstTotal} — and is still not chosen: its handle must be inflated ${R.scrub.handleInflation}× (${R.scrub.handleW}px drawn for the ${R.scrub.handleWanted}px it represents), it is a drag inside a horizontal scroller inside a vertical page, and it is 162 slider values for AT against 3 named destinations. Both reach the middle in one gesture.`);
    ok(R.mid.arrowDisplay === 'flex',
      `X4 ${T}: the arrows still exist on a pointer-fine device (display ${R.mid.arrowDisplay}); the touch half of 022-C is asserted in X7`);

    /* --- X5 the co-dependent set survives the admin's own gutter, peek included ------------------ */
    ok(R.set.tile === 96 && R.set.gap === 10 && R.set.fade === 16,
      `X5 ${T}: the rail is the app's own — card ${R.set.tile} · gap ${R.set.gap} · fade ${R.set.fade} are app.css's ≤480px values verbatim (build.js checks them against app.css itself)`);
    ok(R.set.gut === 16 && R.set.peekClear > R.set.fade,
      `X5 ${T}: and the one number that changes — this page's 16px gutter against the catalogue's 14px — still leaves the peek clear of the fade (${R.set.peekTotal}px de peek, ${R.set.peekClear}px libres sobre una franja de ${R.set.fade}px; production dejaría 27)`);
    ok(R.set.tileW >= 44 && R.set.tileH >= 44,
      `X5 ${T}: a tile clears the admin's 44px floor in both directions (${R.set.tileW}×${R.set.tileH}, cover ${R.set.coverRatio}; the list row's thumb is 40px)`);

    /* --- X6 the mark. 1.4.11's 3:1 floor, in BOTH themes, and the ring that would have failed ---- */
    ok(R.mark.ringVsPage >= 3,
      `X6 ${T}: the marked cover's ring clears 3:1 against the page (${R.mark.ringVsPage}:1 on 064's --stroke, ${R.mark.ringW})`);
    ok(theme !== 'dark' || R.mark.primaryVsPage < 3,
      `X6 ${T}: and the obvious --color-primary ring is why it is not primary (${R.mark.primaryVsPage}:1 — under 3:1 in dark, the failure round 7 caught in a control that looked fine)`);
    ok(R.mark.tickVsBadge >= 4.5 && R.mark.capVsFill >= 4.5 && R.mark.weightOn === '600' && R.mark.weightOff === '400',
      `X6 ${T}: the state is on four channels like R7b's chip, not one (tick ${R.mark.tickVsBadge}:1, label ${R.mark.capVsFill}:1, peso ${R.mark.weightOff}→${R.mark.weightOn}, aria-pressed ${R.mark.aria})`);
    ok(/caja \d+ de \d+/.test(R.mark.label || ''),
      `X6 ${T}: and a tile's accessible name still SAYS the position in words — a screen reader has no geometry to read it off, so the words never go away for AT (“${R.mark.label}”)`);

    /* --- X6 (cont.) keyboard, and the ACCESSIBILITY THAT IS NOW LOAD-BEARING. R9's sharpest finding:
       for a screen reader the position words do not go away when a rail replaces them, they become the
       ONLY channel left, because a rail's whole claim is that the eye reads position off geometry and
       AT has none. With the rail shipped that is no longer hypothetical, so every part of it is
       asserted: the tile's real box number (above), the roving tabindex, and the zone bar's own three
       real stops with the full phrase as each one's accessible name. --- */
    ok(R.D.tileStops === 1,
      `X6 ${T}: a roving tabindex makes the whole rail ONE tab stop (${R.D.tileStops} de ${R.D.tiles} tiles — one stop per game would be up to ${R.mid.slots})`);
    ok(R.D.barStops === 3 && R.bar.hits.every(h => h >= 44) && R.bar.current === 1
      && R.bar.aria.every(a => /^Ir a más a la (izquierda|derecha) de |^Ir a al medio de /.test(a || '')),
      `X6 ${T}: and the zone bar is three real 44px stops whose accessible names are the developer's own full phrases (${R.bar.hits.join('/')}px; ${R.bar.aria.join(' · ')}), with exactly ${R.bar.current} marked aria-current`);
    ok(R.bar.state && R.bar.state.strokeVsPage >= 3 && R.bar.state.labelVsFill >= 4.5
      && R.bar.state.weightOn === '600' && R.bar.state.weightOff === '400',
      `X6 ${T}: the readout carries its state on R7b's chip channels, not on colour alone (borde ${R.bar.state.strokeVsPage}:1, etiqueta ${R.bar.state.labelVsFill}:1 sobre el relleno, peso ${R.bar.state.weightOff}→${R.bar.state.weightOn}) — and no tick glyph, because it changes while you fling and would shift the labels under your thumb`);
    ok(R.D.stops <= 10,
      `X6 ${T}: tab stops inside an open estante: ${R.D.stops} (riel 1 + barra ${R.D.barStops} + pie 2 + 022-C's two arrows, which leave the layout on touch; R9 measured A at 9 and C at 12)`);

    /* --- X8 fixture honesty at rail density ----------------------------------------------------- */
    for (const h of R.honest) {
      ok(h.accountsForAll && h.extraCovers === 0,
        `X8 ${T} estante ${h.sid}: every one of the ${h.slots} slots is accounted for and no cover implies a game that does not exist (${h.tiles} tiles + ${h.bandSlots} en franjas = ${h.slots}, covers de más ${h.extraCovers})`);
      ok(h.geomOff === 0 && h.bandOff === 0 && h.scrollW === h.wantW,
        `X8 ${T} estante ${h.sid}: and the rail's geometry is the shelf's real geometry, so every distance measured on it is true (scrollWidth ${h.scrollW} = ${h.wantW}; tiles fuera de lugar ${h.geomOff}, franjas ${h.bandOff})`);
      ok(h.caps.every(c => /caja(s)? sin título en este boceto/.test(c)),
        `X8 ${T} estante ${h.sid}: the stretch it cannot show says so, in the run's real length (${h.caps.join(' · ')})`);
    }

    /* --- X10 THE FLOW THE ROUND WAS BUILT TO TEST: search → the rail is already on the answer -----
       R9 drove this in both variants and costed the picture at 214px against the sentence's 78px,
       calling B's collapsed row its weak point: it had dropped the zone to make the rail the only
       position channel, so before you tapped you knew LESS. R10 ships the picture AND puts the words
       back on the collapsed row, so this is re-pointed from "it still loses" to "it keeps both halves".
       78px stays in the README as the sentence's recorded cost. --- */
    ok(R.flow.isPicture && R.flow.vis.centred && R.flow.vis.left >= 2 && R.flow.vis.right >= 2,
      `X10 ${T}: the rail flow works — search “dixit”, tap the row, and the estante's rail is scrolled to it, marked, ${R.flow.vis.left} real neighbours left and ${R.flow.vis.right} right (${R.flow.vis.names.join(' | ')})`);
    ok(/Más a la izquierda|Al medio|Más a la derecha/.test(R.flow.collapsed.sub) && /Estante/.test(R.flow.collapsed.sub),
      `X10 ${T}: and the half R9 measured B throwing away is back — the collapsed row says which end to walk to before you tap (“${R.flow.collapsed.sub}”), so the words are the coarse answer and the rail the precise one`);
    ok(R.flow.words === 0 && R.flow.expH > 0,
      `X10 ${T}: the expansion itself is the picture and says nothing twice (${R.flow.words} frases, ${R.flow.expH}px — R9 measured this at 214px against 78px for the sentence alone, and the developer chose the picture)`);

    /* --- X9 THE ZONE WORDS — the developer's actual question, and the second job R10 gives them ----
       R8 made a row lead with its zone; R9's census measured that claim out of existence (every
       rendered row of every estante derived the IDENTICAL word) and dropped it inside an estante while
       keeping it in a search result. R10 keeps that split and adds the part R9 left on the table: the
       vocabulary the census retired as DESCRIPTION is exactly right as NAVIGATION, because the three
       words name the only three positions a rail's edge-fade can ever tell apart. So the count inside
       an estante is still zero, and the same three words are the jump targets. */
    const zs = R.zones.perShelf;
    ok(zs.every(s => s.rowsWithZone === 0),
      `X9 ${T}: inside an open estante nothing describes the position in words (${zs.map(s => s.sid + ':' + s.rowsWithZone).join(' · ')} — and there are ${zs.map(s => s.rows).join('/')} rows left in there to do it with)`);
    ok(zs.every(s => s.distinct === 1),
      `X9 ${T}: which is what the census earned — every rendered row of every estante had derived the IDENTICAL word (${zs.map(s => s.sid + ' (' + s.n + ' cajas): ' + s.renderedZones.join('/')).join(' · ')})`);
    ok(zs.filter(x => x.jumps.length).length === zs.filter(x => x.n > 30).length
      && zs.filter(x => x.jumps.length).every(x => x.jumps.length === 3
        && x.jumpLabels.join('|') === 'Izquierda|Medio|Derecha'
        && x.jumps.some(a => /más a la izquierda/.test(a)) && x.jumps.some(a => /al medio/.test(a)) && x.jumps.some(a => /más a la derecha/.test(a))),
      `X9 ${T}: and the retired vocabulary comes back as navigation, unchanged — the label is the short form and the accessible name is the developer's own phrase (${zs.map(x => x.n + ':' + (x.jumpLabels.join('/') || 'sin barra')).join(' · ')})`);
    /* the generalisation past the fixture, computed rather than hand-derived: the fixture's named games
       sit in ONE contiguous run per shelf (R8's device for making every index real), so its 100% is
       partly its own doing. What is not is the arithmetic — a page is 8 consecutive boxes and a zone is
       a third of the shelf, so the word can only change across a page when the page straddles a
       boundary. It runs 60% on the club's smallest estante and 90% on its biggest, i.e. the word is the
       same on every row of most pages at every shelf length, and more so the longer the shelf. */
    ok(R.zones.window.every(w => w.oneWordPct >= 60) && R.zones.window.find(w => w.n === 162).oneWordPct >= 88,
      `X9 ${T}: and that is not just the fixture's contiguous run — a page of 8 boxes straddles a third-boundary in only ${R.zones.window.map(w => w.crossing + '/' + w.starts).join(', ')} start positions, so one word covers every row of ${R.zones.window.map(w => w.n + ':' + w.oneWordPct + '%').join(' · ')} of pages`);
    ok(R.zones.searchA.length > 0 && R.zones.searchA.every(s => /izquierda|Al medio|derecha/.test(s)),
      `X9 ${T}: in a search result it stays and still leads the line (${R.zones.searchA.slice(0, 3).join(' · ')})`);

    /* --- X2 (cont.) 1.4.10 reflow at the phone width: a rail is a scoped horizontal scroller inside
       the page's vertical one, which is the exception 1.4.10 allows and what the catalogue already
       ships. What it may NOT do is give the PAGE a second axis. R10: one page instead of three, and
       measured on the longest estante with a box marked, which is the tallest the surface ever gets. --- */
    for (const st of ['shut', 'open', 'marked']) {
      await p.evaluate(async k => { Object.assign(V, { listaQ: '' }); resetGrps();
        if (k !== 'shut') V.grpOpen.s4 = true;
        S.screen = 'estantes'; render(); await new Promise(r => setTimeout(r, 380));
        if (k === 'marked') { document.querySelector('#main .etile').click(); await new Promise(r => setTimeout(r, 420)); }
      }, st);
      const m = await p.evaluate(() => window.__m());
      ok(m.overflowX <= 0, `X2 ${T} ${st} 420px: the rail adds no second page axis — 1.4.10 (${m.overflowX}px)`);
      await (await p.$('#device')).screenshot({ path: `${OUT}/r10-estante-${st}-${T}.png` });
    }
  }
  await p.evaluate(() => delete document.documentElement.dataset.theme);
  await p.evaluate(() => { Object.assign(V, seed062(true), { ed: null, ordering: null, memQ: '', listaQ: '' }); resetGrps(); go('panel'); });
  await p.waitForTimeout(260);

  /* --- X7 TOUCH: 022-C's other half, and the gesture conflict a horizontal scroller inside a
     vertical one is supposed to cause. Driven through CDP's real input pipeline (touchStart /
     touchMove× / touchEnd), not synthetic JS events, which do not drive native scrolling at all. --- */
  {
    const tctx = await b.newContext({ viewport: { width: 420, height: 1100 }, hasTouch: true, isMobile: true, deviceScaleFactor: 2 });
    const tp = await tctx.newPage();
    tp.on('pageerror', e => errs.push('touch-r9: ' + e.message));
    await tp.goto(URL); await tp.evaluate(() => document.fonts.ready);
    const cdp = await tctx.newCDPSession(tp);
    const openB = async () => { await tp.evaluate(async () => { Object.assign(V, { listaQ: '', adding: null }); resetGrps(); V.grpOpen.s4 = true; S.screen = 'estantes'; render(); await new Promise(r => setTimeout(r, 420)); }); };
    const at = () => tp.evaluate(() => ({ rail: Math.round((document.querySelector('#main .erail') || { scrollLeft: 0 }).scrollLeft), page: Math.round(document.querySelector('.scroller').scrollTop) }));
    const swipe = async (x, y, dx, dy, steps = 12) => {
      await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ x, y }] });
      for (let i = 1; i <= steps; i++) {
        await cdp.send('Input.dispatchTouchEvent', { type: 'touchMove', touchPoints: [{ x: x + dx * i / steps, y: y + dy * i / steps }] });
        await tp.waitForTimeout(8);
      }
      await cdp.send('Input.dispatchTouchEvent', { type: 'touchEnd', touchPoints: [] });
      await tp.waitForTimeout(700);
    };
    await openB();
    const box = await tp.evaluate(() => { const r = document.querySelector('#main .erail').getBoundingClientRect(); return { x: Math.round(r.left + r.width / 2), y: Math.round(r.top + r.height / 2) }; });
    const t022 = await tp.evaluate(() => { const btn = document.querySelector('#main .erail-btn'); const c = getComputedStyle(btn);
      return { display: c.display, w: Math.round(btn.getBoundingClientRect().width), inTab: btn.tabIndex >= 0 && c.display !== 'none',
        tile: (() => { const r = document.querySelector('#main .etile').getBoundingClientRect(); return Math.round(r.width) + 'x' + Math.round(r.height); })() }; });
    ok(t022.display === 'none' && t022.w === 0 && !t022.inTab,
      `X7 022-C holds on touch: the arrows are removed from the layout, not hidden (display ${t022.display}, ${t022.w}px, en el orden de tabulación ${t022.inTab}) — no dead tap target over the swipe area`);

    const g = {};
    for (const [k, dx, dy] of [['h', -250, 0], ['v', 0, -250], ['mostlyV', -40, -250], ['mostlyH', -250, -40]]) {
      await openB();
      const b0 = await at(); await swipe(box.x, box.y, dx, dy); const a0 = await at();
      g[k] = { rail: a0.rail - b0.rail, page: a0.page - b0.page };
    }
    ok(g.h.rail > 100 && g.h.page === 0,
      `X7 a horizontal swipe that starts on a tile scrolls the rail and never the page (riel Δ${g.h.rail}px, página Δ${g.h.page}px)`);
    ok(g.v.page > 100 && g.v.rail === 0,
      `X7 a vertical swipe that starts on a tile scrolls the page and never the rail (página Δ${g.v.page}px, riel Δ${g.v.rail}px)`);
    ok(g.mostlyV.rail === 0 && g.mostlyV.page > 100 && g.mostlyH.page === 0 && g.mostlyH.rail > 100,
      `X7 and the axis lock holds on a sloppy thumb, both ways (casi-vertical riel Δ${g.mostlyV.rail} página Δ${g.mostlyV.page} · casi-horizontal riel Δ${g.mostlyH.rail} página Δ${g.mostlyH.page}) — this is what \`touch-action: manipulation\` buys over \`pan-x\``);

    /* flings, the touch answer to R4's 27 presses */
    await openB();
    const target = await tp.evaluate(() => { const w = document.querySelector('#main .erail-wrap'), r = w.querySelector('.erail'); const c = getComputedStyle(w), px = k => parseFloat(c.getPropertyValue(k)); return Math.round(px('--egut') + 81 * (px('--etile') + px('--egap')) - (r.clientWidth - px('--etile')) / 2); });
    let n = 0, pos = 0, stall = 0;
    while (pos < target - 40 && n < 40) {
      const b0 = pos; await swipe(box.x, box.y, -300, 0, 6); pos = (await at()).rail; n++;
      if (pos - b0 < 5) { if (++stall > 2) break; } else stall = 0;
    }
    /* the fling count is deliberately a loose floor: a fling's distance is the velocity the FINGER
       supplied, so a synthesized one varies run to run (8 flings of ~1340px and 15 of ~592px both
       measured across runs of this same loop). The deterministic number is X4's 27 arrow presses; this
       asserts only what does not vary — that a phone needs several flings and not one, i.e. that the
       far side of a 162-box estante is nowhere near a thumb. */
    ok(n >= 4 && pos >= target - 40,
      `X4 on a phone, where 022-C leaves no arrows, the same trip is ${n} flings of ~${Math.round(pos / n)}px (${pos}px de ${target}px; 8–15 flings across runs, since a fling is whatever velocity the thumb gave it) — the rail can BE the answer, it cannot FIND it; search is 2 taps in every variant`);

    /* a sheet over the rail must make it inert, like every other surface under a sheet */
    await openB();
    await tp.evaluate(async () => { document.querySelector('[data-act="v-shelf-sheet"]').click(); await new Promise(r => setTimeout(r, 540)); });
    const b1 = await at(); await swipe(box.x, box.y, -250, 0); const a1 = await at();
    const so = await tp.evaluate(() => !!document.querySelector('.sheet.open'));
    ok(so && a1.rail - b1.rail === 0 && a1.page - b1.page === 0,
      `X7 with a bottom sheet open the rail underneath is inert like everything else (hoja abierta ${so}, riel Δ${a1.rail - b1.rail}, página Δ${a1.page - b1.page})`);
    await tp.evaluate(() => closeAll());
    await tctx.close();
  }

  /* ================= ROUND 10: ONE action system for the whole admin =================
     Developer: "Those too big and kill balance ... there are 'text actions' like 'Ver en la ludoteca'
     and 'Quitar del estante'. We need a consistent way to represent actions everywhere with its
     corresponding hierachy and correct balance to fix the currently broken rythm."
     064 wrote the PAINT of a role and nothing about the SHAPE a role takes in which place, so each
     place invented one. The rule this round lands is one sentence — THE CONTEXT PICKS THE ANATOMY,
     THE ROLE PICKS THE PAINT — with four anatomies and no fifth (A1 outlined · A2 text · A3 icon ·
     A4 sheet row), and it is enforced twice: 064's audit-admin.js checks A1–A9 per screen (a rule that
     lives only here drifts the moment a sketch is edited alone — round 4 and round 9 both found a
     control nothing audited), and M1–M6 below check the thing only a walk can see. */
  for (const theme of ['light', 'dark']) {
    await p.evaluate(t => t === 'dark' ? document.documentElement.dataset.theme = 'dark' : delete document.documentElement.dataset.theme, theme);
    const A = await p.evaluate(() => window.__r10());
    const T = theme;

    /* --- M1 THE CENSUS, AS AN ASSERTION. One anatomy per context × role, across the whole walk. This
       is the finding itself: before this round five pairs rendered two ways, one tap apart. --- */
    const split = Object.entries(A.pairs).filter(([, v]) => Object.keys(v).length > 1);
    ok(split.length === 0,
      `M1 ${T}: every context × role has exactly ONE anatomy across the walk (${Object.keys(A.pairs).length} pares medidos${split.length ? ' — ' + split.map(([k, v]) => k + ': ' + Object.entries(v).map(([a, who]) => a + ' ⟨' + who.slice(0, 3).join(', ') + '⟩').join('  vs  ')).join(' · ') : ''})`);

    /* --- M2 FOUR ANATOMIES AND NO FIFTH ------------------------------------------------------- */
    const extra = Object.keys(A.kinds).filter(k => !['A1', 'A2', 'A3', 'A4', 'CHIP'].includes(k));
    ok(extra.length === 0,
      `M2 ${T}: every action is one of the four anatomies, plus the chip row for "pick one of N" (${Object.entries(A.kinds).map(([k, n]) => k + '×' + n).join(' · ')})`);

    /* --- M3 HIERARCHY PER BLOCK. A block may hold one Principal and one Secundaria; two Secundarias
       and no Principal is what "kills the balance" — the page asks for nothing and shouts twice. The
       Estantes page is the case the developer named: it carried Ordenar + Agregar juegos + Nuevo
       estante, three outlines and no Principal. --- */
    const piles = Object.entries(A.pages).flatMap(([k, v]) => v.blocks.filter(b => b.sec > 1 || b.pri > 1).map(b => k + '/' + b.cls + ' ' + b.pri + 'P/' + b.sec + 'S ' + b.labels.join('+')));
    ok(piles.length === 0,
      `M3 ${T}: no BLOCK piles up outlined actions of one rank — at most one Principal and one Secundaria each (${piles.join(' · ') || Object.entries(A.pages).filter(([, v]) => v.blocks.length).map(([k, v]) => k + ' [' + v.blocks.map(b => b.cls + ':' + b.labels.join('+')).join('] [') + ']').join(' · ')})`);
    ok(A.pages.estantes.outlined <= 1 && A.pages['estante-abierto'].outlined <= 2
      && A.pages['estante-abierto'].blocks.every(b => b.pri + b.sec === 1),
      `M3 ${T}: the page whose job is finding carries ${A.pages.estantes.outlined} outlined action shut and ${A.pages['estante-abierto'].outlined} with an estante open — one per block, not one per page (${A.pages['estante-abierto'].blocks.map(b => b.cls + ':' + b.labels.join('+')).join(' · ')}); R8 had three, and the third was on the page itself`);

    /* --- M4 A PAGE-LEVEL ACTION IS NEVER OUTLINED (rule 2). It sits under content it does not belong
       to, and the census caught the consequence of treating it as Secundaria: `.pacts` was applying the
       borderless −12px pull to an outlined button, so its stroke hung 12px past the page's left content
       edge — invisible to 064's audit, which only ever measured the right edge. --- */
    const pacts = Object.entries(A.pages).flatMap(([k, v]) => v.pacts.map(x => [k, x]));
    ok(pacts.length > 0 && pacts.every(([, x]) => !x.outlined),
      `M4 ${T}: every page-level action is a text action (${pacts.map(([k, x]) => k + ':' + x.cls).join(' · ')})`);

    /* --- M5 THE 44px FLOOR, on everything you tap and not only on buttons. The census found two
       settings panels declaring 40px for rows that open a sheet, and nothing had ever looked: 064's
       audit only measured buttons. The chip is why this measures the HIT box — 061's filter chip is a
       32px pill whose ::after bleeds its target to 44, which is legal. --- */
    ok(A.floor.length === 0,
      `M5 ${T}: every tap target in the walk clears 44px (${A.floor.slice(0, 5).join(' · ') || 'ninguno por debajo'})`);

    /* --- M6 A SHEET HAS NO BUTTONS (R7b), on every sheet in the walk ------------------------- */
    const badSheet = A.sheets.filter(s => !s.open || s.buttons !== 0 || s.heights.some(h => h !== '48px'));
    ok(badSheet.length === 0,
      `M6 ${T}: every sheet's actions are 48px rows and not buttons (${A.sheets.map(s => s.name + ': ' + s.rows.length + ' filas de ' + s.heights.join('/') + ', ' + s.buttons + ' botones').join(' · ')})`);
    const noCancel = A.sheets.filter(s => s.rows.some(r => /^Cancelar/.test(r)) && !/^Cancelar/.test(s.rows[s.rows.length - 1] || ''));
    ok(noCancel.length === 0,
      `M6 ${T}: and Cancelar is the last row wherever it appears (${A.sheets.map(s => s.rows.join(' → ')).join(' | ')})`);
  }
  await p.evaluate(() => delete document.documentElement.dataset.theme);
  await p.evaluate(() => { V.listaQ = ''; resetGrps(); go('panel'); });
  await p.waitForTimeout(260);

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
    /* 065 R8: `asignar` is retired, and the two fields it used to contribute now live in sheets —
       Renombrar (off an estante's options) and Nuevo estante. Both are measured, so K1 keeps its
       subjects rather than losing them with the screen. render() is used, not go(): go() swaps the
       body 230ms later and this census is synchronous. */
    V.listaQ = ''; V.ordering = null; V.adding = null; resetGrps(); V.grpOpen.s1 = true;
    S.screen = 'estantes'; render(); grab();
    const fake = (act, id) => { const b = document.createElement('button'); b.dataset.act = act; if (id) b.dataset.id = id; document.body.appendChild(b); return b; };
    vAct(fake('v-rename', '1')); grab(); closeAll();
    vAct(fake('v-new-shelf')); grab(); closeAll();
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

  /* K3 — a bottom sheet with the keyboard open sits ON TOP of the keyboard, not under it.
     065 R8: this was driven through Asignar → Renombrar, and Asignar is gone. It is not dropped: the
     rule follows the sheets that still carry a text field, and there are now TWO of them — Renombrar,
     which moved into an estante's own options sheet, and "Nuevo estante", which became a sheet this
     round. Each is driven end to end. */
  for (const [what, open, field] of [
    ['renombrar', "V.listaQ=''; V.ordering=null; resetGrps(); V.grpOpen.s1 = true; go('estantes'); setTimeout(() => { document.querySelector('[data-act=\"v-shelf-sheet\"][data-id=\"1\"]').click(); setTimeout(() => document.querySelector('#sheet-act [data-act=\"v-rename\"]').click(), 260); }, 320);", 'ren-in'],
    ['nuevo estante', "V.listaQ=''; V.ordering=null; resetGrps(); go('estantes'); setTimeout(() => document.querySelector('[data-act=\"v-new-shelf\"]').click(), 320);", 'shelf-new'],
  ]) {
    await p.evaluate(() => closeAll());
    await p.evaluate(s => (0, eval)(s), open);
    await p.waitForTimeout(1100);
    await p.evaluate(id => document.getElementById(id).focus(), field);
    await p.waitForTimeout(380);
    const k3 = await p.evaluate(() => window.__kb());
    ok(k3.kbd && k3.kbTop != null, `K3 the ${what} sheet opens the keyboard (kbd ${k3.kbd})`);
    ok(k3.sheetBottom != null && k3.sheetBottom <= k3.kbTop + 1, `K3 the ${what} sheet sits above the keyboard (sheet bottom ${k3.sheetBottom}, keyboard top ${k3.kbTop})`);
    ok(k3.focusBottom != null && k3.focusBottom <= k3.kbTop, `K3 the ${what} field is above the keyboard (field bottom ${k3.focusBottom}, keyboard top ${k3.kbTop})`);
    ok(k3.sheetTop >= 0, `K3 the ${what} sheet is not pushed off the top of the screen (top ${k3.sheetTop})`);
    await (await p.$('#device')).screenshot({ path: `${OUT}/kbd-sheet-${what.replace(/\s/g, '-')}.png` });
    await p.evaluate(() => closeAll());
    await p.waitForTimeout(300);
  }

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
  /* --- round 7 on the wide viewport: the panel, the one save bar and the toggle hold there too --- */
  const CD = await wide.evaluate(() => window.__r7());
  const dg = [...new Set(CD.panel.gaps)];
  ok(CD.panel.strays.length === 0 && dg.length === 1 && CD.panel.padTop === CD.panel.padBottom && CD.panel.padTop === dg[0],
    `C1 desk: the Ajustes panel keeps one rhythm (gaps ${CD.panel.gaps.join('/')}, padding ${CD.panel.padTop}/${CD.panel.padBottom})`);
  ok([...new Set(CD.barCensus.bars.map(b => b.split(':').slice(1).join(':').replace(/ \(pad .*/, '')))].length === 1 && CD.barCensus.second.length === 0,
    `C3 desk: still one save bar (${CD.barCensus.bars.slice(0, 3).join(' | ')})`);
  ok(Math.abs(CD.secBarDirty.lastRight - CD.secBarDirty.contentEdge) <= 0.5,
    `C3 desk: Guardar lands on the bar's content edge (${CD.secBarDirty.lastRight} vs ${CD.secBarDirty.contentEdge})`);
  const dBad = Object.entries(CD.toggles).flatMap(([page, t]) => [['off', t.off], ['on', t.on]]
    .filter(([, s]) => s.bw !== 1 || s.borderVsBg < 3 || s.h !== 44 || Math.abs(s.right - s.edge) > 0.5)
    .map(([k, s]) => `${page}/${k} ${s.bw}px ${s.borderVsBg}:1 ${s.h}px ${s.right}≠${s.edge}`));
  ok(dBad.length === 0, `C4 desk: the reorder toggle is a real 44px button on the content edge in both states (${dBad.join(' · ') || Object.keys(CD.toggles).join(', ')})`);
  const dType = Object.entries(CD.typing).filter(([, t]) => !t.sameNode || t.boxes.length !== 1);
  ok(dType.length === 0, `C5 desk: typing still never replaces the field (${dType.map(([k]) => k).join(',') || Object.entries(CD.typing).map(([k, t]) => k + ' ' + t.boxes[0]).join(' · ')})`);

  /* --- round 9 on the wide viewport. The rail's whole argument is geometric, so a second width is
     where a geometric argument either holds or falls over. It holds: the set is the same four numbers,
     a wider rail shows more boxes per press — and therefore reaches the middle in FEWER presses, which
     is the one measurement that improves with width and the reason the rail's problem is a phone
     problem first. 024 still resolves to three states, and no 2-D page scroll appears at either
     width (1.4.10). --- */
  for (const theme of ['light', 'dark']) {
    await wide.evaluate(t => t === 'dark' ? document.documentElement.dataset.theme = 'dark' : delete document.documentElement.dataset.theme, theme);
    const RD = await wide.evaluate(() => window.__r9());
    ok(RD.set.tile === 96 && RD.set.gap === 10 && RD.set.fade === 16 && RD.set.peekClear > RD.set.fade,
      `X5 desk ${theme}: the co-dependent set does not change with the viewport, and the peek still clears the fade (${RD.set.fullTiles} cajas enteras en ${RD.set.wrapW}px, ${RD.set.peekClear}px libres)`);
    ok(RD.fade.n === 3 && RD.fade.middleAllSame && RD.D.railIndicators === 0,
      `X2 desk ${theme}: 024-A holds at 1440 too and still resolves to ${RD.fade.n} positions over ${RD.fade.slots} cajas (${RD.fade.states.join(' ')})`);
    ok(RD.mid.presses < X_PRESSES_PHONE && RD.mid.presses >= 8 && RD.mid.barTaps === 1 && RD.mid.barOff === 0,
      `X4 desk ${theme}: a wider rail is a better navigator and still not one — ${RD.mid.presses} presses of ${RD.mid.perPress}px (${RD.mid.cardsPerPress} cajas) against ${X_PRESSES_PHONE} on the phone, and the zone bar is one tap at either width`);
    ok(RD.mark.ringVsPage >= 3 && (theme !== 'dark' || RD.mark.primaryVsPage < 3),
      `X6 desk ${theme}: the marked cover's state still clears 3:1 (${RD.mark.ringVsPage}:1; --color-primary would be ${RD.mark.primaryVsPage}:1)`);
    ok(RD.D.tileStops === 1 && RD.honest.every(h => h.accountsForAll && h.extraCovers === 0 && h.scrollW === h.wantW),
      `X6/X8 desk ${theme}: one tab stop per rail, and every slot still accounted for with no invented cover (${RD.honest.map(h => h.tiles + '+' + h.bandSlots + '=' + h.slots).join(' · ')})`);
    for (const [name, setup] of [['10-estante-riel', "V.listaQ=''; resetGrps(); V.grpOpen.s4 = true; go('estantes');"]]) {
      await wide.evaluate(s => { try { (0, eval)(s); } catch (e) {} }, setup);
      await wide.waitForTimeout(280);
      const m = await wide.evaluate(() => window.__m());
      ok(m.overflowX <= 0, `X2 ${name} desk ${theme}: a rail inside the page's vertical scroller adds no second page axis — 1.4.10 (${m.overflowX}px)`);
      await (await wide.$('#device')).screenshot({ path: `${OUT}/${name}-desk-${theme}.png` });
    }
  }
  await wide.evaluate(() => { delete document.documentElement.dataset.theme; V.est = 'A'; resetGrps(); go('panel'); });
  await wide.waitForTimeout(240);

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
