/* ================= 065: the composition =================
   One router, one render, one patch, one event layer, one set of counters — and the phone-keyboard
   behaviour 059/061 flagged and nobody ever tested. Nothing here restyles a page: if a page looks
   wrong in the walk, the fix goes back into 060/061/062/063 and build.js picks it up. */

/* ---- counters: sliced from 062 by build.js, not restated here ----------------------------
   Each sketch had its own. 060's dashboard read a frozen literal, 061's badge read jCount('draft'),
   062's pages read the live V state and 063 hard-coded {juegos:3, estantes:84, niveles:7}. Alone each
   is self-consistent; composed, the Admin boxes and the tab badges stopped agreeing with the pages the
   moment you did anything. 062's DATA()/cnt() — the only fully live pair — is now THE pair, and every
   sketch's boxData() reads it and nothing else. */

/* ---- opening the editor on the game you actually tapped ---- */
function openEditor(g) {
  const st = g.status || 'published';
  seed(st);
  Object.assign(BGG, { name: g.name, year: g.year || BGG.year, hue: g.hue == null ? BGG.hue : g.hue });
  E.saved.name = g.name; E.ed.name = g.name;
  E.failed = g.enr === 'failed';
  go('editar');
}

/* ---- ONE router ----------------------------------------------------------------
   Every move between admin pages goes through here, so the unsaved-changes guard (063), the
   soft content swap (059) and the scroll/focus reset happen the same way everywhere. */
function go(target) {
  if (S.screen === 'editar' && target !== 'editar' && dirty()) { E.pendingNav = target; return openAct(leaveSheet(), document.activeElement); }
  V.ordering = null; V.renaming = false;
  S.screen = target; closeAll(); softSwap();
}
/* 063 navigated with a full render() — the header, tab bar and drawer were torn down and rebuilt,
   so entering or leaving the editor flashed while every other page swapped softly. One rule now. */
function nav(target) { return go(target); }

function adminBody() {
  return ({
    panel: () => pageHead() + panelBody(),
    juegos: juegosBody, secciones: webBody, seccion: secBody, estantes: estBody,
    /* 065 R8: `asignar` is gone — an expanded estante on the Estantes page does its job. */
    niveles: nivBody, staff: staffBody, editar: editBody,
  })[S.screen]();
}
const publicBody = () => ['Destacados del club', 'Descubre el hobby', 'Recientemente añadidos'].map(t =>
  `<div class="fake-shelf"><h2>${t}</h2><div class="fake-rail">${'<div class="fake-poster"></div>'.repeat(8)}</div></div>`).join('') +
  '<p class="ph-note">Catálogo público (sin cambios).</p>';
const loginBody = () => `<div class="login"><h1 class="ptitle" style="text-align:center">Ingresar a Admin</h1>
  <p class="psub" style="text-align:center">Te mandamos un link por mail para entrar.</p>
  <div class="field"><label for="em">Email</label><input id="em" type="email" placeholder="tu@email.com"></div>
  <button class="btn b-pri btn-block" data-act="login">Enviarme el link</button></div>`;

/* ---- render ---- */
const device = document.getElementById('device');
function fitNav() { document.body.style.paddingTop = (document.getElementById('state-nav').offsetHeight + 8) + 'px'; }
window.addEventListener('resize', fitNav);
device.addEventListener('scroll', () => { if (device.scrollTop || device.scrollLeft) device.scrollTop = device.scrollLeft = 0; });

const KBD = { open: false };
function render() {
  fitNav();
  const admin = S.mode === 'admin', desk = S.vp === 'desk', ed = S.screen === 'editar';
  device.className = 'device polish r6 pen-chip' + (desk ? ' desk' : '') + (admin ? ' has-tabs' : '') + (KBD.open ? ' kbd' : '');
  const body = admin ? adminBody() : S.mode === 'public' ? publicBody() : loginBody();
  device.innerHTML = `<div class="scroller">${header()}${admin && desk ? tabBar() : ''}<main id="main" class="${ed ? 'wide' : ''}">${body}</main></div>
    ${admin && !desk ? tabBar() : ''}${drawer()}${admin ? accountSheet() + '<div class="sheet" id="sheet-act" role="dialog" aria-modal="true"></div>' : ''}
    <div class="toast" id="toast">${ic('check')}<span></span></div>
    <div class="snack" id="snack" role="status"><span></span><button class="tbtn" hidden></button></div>
    ${KBD.open ? '<div class="kbdsim" aria-hidden="true">TECLADO SIMULADO</div>' : ''}`;
  document.getElementById('notes').innerHTML = NOTES;
  renderWalk();
  if (S.toast) { showToast(S.toast); S.toast = null; }
}
const $ = sel => device.querySelector(sel);

/* Header, tabs and drawer persist; only the page content swaps (LiveView navigate in one live_session). */
function softSwap() {
  const main = $('#main');
  if (!main || S.mode !== 'admin') return render();
  main.classList.add('swapping');
  setTimeout(() => {
    const top = activeTop();
    main.className = (S.screen === 'editar' ? 'wide' : '');
    main.innerHTML = adminBody();
    device.querySelectorAll('.tabs [data-tab]').forEach(b => {
      if (b.dataset.tab === 'account') return;
      const on = b.dataset.tab === top; b.classList.toggle('on', on); on ? b.setAttribute('aria-current', 'page') : b.removeAttribute('aria-current');
    });
    device.querySelectorAll('.drawer .dlink[data-nav]').forEach(b => {
      const on = b.dataset.nav === top; b.classList.toggle('on', on); on ? b.setAttribute('aria-current', 'page') : b.removeAttribute('aria-current');
    });
    $('.scroller').scrollTop = 0;
    syncBadges();
    main.classList.remove('swapping');
    /* A new page starts at its own title, not wherever the last page's focus was. Never a field:
       the editor's title IS an <input>, so focusing "the heading" there popped the phone keyboard
       just for arriving on the page. Landing focus goes on the page's heading text, silently. */
    const h = main.querySelector('h1.ptitle, h1, .thead');
    if (h && !isField(h)) { h.setAttribute('tabindex', '-1'); h.style.outline = 'none'; h.focus({ preventScroll: true }); }
    renderWalk();
  }, 100);
}

/* ---- LiveView-style patch: keeps focus, caret and scroll ---- */
function patch() {
  const main = $('#main'); if (!main || S.mode !== 'admin') return;
  const a = document.activeElement, id = a && device.contains(a) ? a.id : null;
  let pos = null; try { pos = a.selectionStart; } catch (_) {}
  const sc = $('.scroller'), top = sc.scrollTop;
  main.innerHTML = adminBody();
  if (id) { const n = document.getElementById(id); if (n) { n.focus({ preventScroll: true }); try { if (pos != null) n.setSelectionRange(pos, pos); } catch (_) {} } }
  sc.scrollTop = top;
  syncBadges();
}
/* typing only touches what depends on "dirty" (LiveView would diff the same way) */
function sync() { const bar = $('#ebar'); if (bar) bar.outerHTML = barHtml(); }
function refreshList() { const l = $('#jlist'); if (l) l.innerHTML = listHtml(); const f = $('#jfilters'); if (f) f.innerHTML = filtersHtml(); syncBadges(); }
/* 065 R7: the same rule for 062's three searches. They used to debounce into patch(), which rebuilds
   main.innerHTML — so every keystroke destroyed the focused input, built a new node and put the caret
   back: the blink the developer saw on Estantes, and the same on a sección and on Asignar. 061 had
   already solved it for Juegos (refreshList swaps #jlist and #jfilters and never touches #q-in), which
   is how LiveView would diff it too. One region per search; the field is never in it.
   Identical to the copy in 062's own page — build.js throws if the two ever drift apart.
   065 R8: two searches, not three — `asg-q` went with the Asignar screen, and `lista-q` inherited its
   job ("buscar cualquier juego") on top of its own. */
const QREG = { 'mem-q': ['mem-results', memResHtml], 'lista-q': ['est-groups', estGroupsHtml] };
/* 065 R7b: each query re-derives which estantes are open, so a manual toggle never leaks from one
   query into the next. 065 R8: a query now replaces the groups with a flat result list, so this also
   means leaving a search returns the page to the estantes shut.
   Called from the input path, not from refreshQ, which the toggles themselves go through. */
function resetGrps() { V.grpOpen = {}; V.grpShown = {}; V.gameOpen = null; V.adding = null; V.addShown = 0; V.tileOn = null; V.railAt = {}; }
function refreshQ(id) {
  const reg = QREG[id]; if (!reg) return patch();
  const el = document.getElementById(reg[0]); if (!el) return patch();
  el.innerHTML = reg[1]();
}
function refreshAdd() {
  const inp = $('#add-in'), btn = $('#add-btn'), err = $('#add-err');
  if (!inp) return;
  inp.classList.toggle('invalid', !!J.err); J.err ? inp.setAttribute('aria-invalid', 'true') : inp.removeAttribute('aria-invalid');
  inp.readOnly = J.adding;
  J.adding ? btn.setAttribute('aria-busy', 'true') : btn.removeAttribute('aria-busy');
  btn.innerHTML = J.adding ? '<span class="spin sm"></span>Agregando' : 'Agregar';
  err.textContent = J.err || '';
  $('#jprompt').innerHTML = promptHtml();
}
/* every badge, not just Juegos: 062 only refreshed the Juegos one, so the Estantes and Revisar
   niveles badges kept their load-time number while the pages underneath them emptied out. */
function syncBadges() {
  device.querySelectorAll('.tabs [data-tab]').forEach(t => {
    const k = t.dataset.tab; if (k === 'account') return;
    const ico = t.querySelector('.tab-ico'), b = ico.querySelector('.badge'), n = cnt(k);
    if (n && b) b.textContent = n; else if (n) ico.insertAdjacentHTML('beforeend', `<span class="badge">${n}</span>`); else if (b) b.remove();
  });
  device.querySelectorAll('.drawer .dlink[data-nav]').forEach(r => {
    const n = cnt(r.dataset.nav), b = r.querySelector('.count');
    if (n && b) b.textContent = n; else if (n) r.querySelector('.lbl').insertAdjacentHTML('afterend', `<span class="count" aria-label="${n} pendientes">${n}</span>`); else if (b) b.remove();
  });
}
function flashRow(id) { const r = $(`.glist [data-gid="${id}"]`); if (r) { r.classList.remove('flash'); void r.offsetWidth; r.classList.add('flash'); } }
function flashKey(key) { const r = $(`[data-key="${key}"]`); if (r) { r.classList.remove('flash'); void r.offsetWidth; r.classList.add('flash'); } }
function leave(key, then) { const r = $(`[data-key="${key}"]`); if (!r) return then(); r.classList.add('leaving'); setTimeout(then, 230); }
function snack(msg, action) {
  const s = $('#snack'); if (!s) return;
  s.querySelector('span').textContent = msg;
  const b = s.querySelector('.tbtn'); b.hidden = !action; if (action) { b.textContent = action.label; b.dataset.act = action.act; b.dataset.gameId = action.id || ''; }
  clearTimeout(s._t); s.classList.remove('show'); void s.offsetWidth; s.classList.add('show');
  s._t = setTimeout(() => s.classList.remove('show'), 4000);
}
function refreshSecs(focusId) {
  const steps = $('#sheet-act.open .steps'); if (steps) steps.innerHTML = secsSheet();
  patch();
  document.getElementById(focusId)?.focus({ preventScroll: true });
}

/* ---- overlays (059) ---- */
let returnFocus = null;
function resetSteps(sh) {
  sh.querySelectorAll('.steps').forEach(steps => {
    clearTimeout(steps._t); steps.classList.remove('animating'); steps.style.height = '';
    steps.querySelectorAll('.step').forEach(st => {
      const first = st.classList.contains('step-account');
      st.style.transition = 'none';
      first ? st.removeAttribute('aria-hidden') : st.setAttribute('aria-hidden', 'true'); st.inert = !first;
      void st.offsetWidth; st.style.transition = '';
    });
  });
}
function setStep(sh, name) {
  const steps = sh && sh.querySelector('.steps'); if (!steps) return;
  const from = steps.querySelector('.step:not([aria-hidden="true"])');
  const to = steps.querySelector('.step-' + name);
  if (!to || from === to) return;
  steps.style.height = from.offsetHeight + 'px'; steps.classList.add('animating');
  from.setAttribute('aria-hidden', 'true'); from.inert = true;
  to.removeAttribute('aria-hidden'); to.inert = false;
  void steps.offsetHeight; steps.style.height = to.offsetHeight + 'px';
  clearTimeout(steps._t); steps._t = setTimeout(() => { steps.style.height = ''; steps.classList.remove('animating'); }, 300);
  const f = to.querySelector(name === 'confirm' ? '[data-act="cancel-logout"],[data-act="v-step-back"],[data-act="e-step-back"]'
    : '[data-act="ask-logout"],[data-act="v-staff-confirm"]') || to.querySelector('button');
  f && f.focus({ preventScroll: true });
}
function closeAll() {
  const had = device.querySelector('.drawer.open,.sheet.open');
  device.querySelectorAll('.open').forEach(el => { el.classList.remove('open'); el.style.transform = ''; });
  if (had && returnFocus && document.contains(returnFocus)) returnFocus.focus({ preventScroll: true });
  if (had) returnFocus = null;
}
function openEl(sel, opener) {
  const keep = returnFocus || opener;
  closeAll(); returnFocus = keep;
  const el = device.querySelector(sel); if (!el) return;
  resetSteps(el);
  void el.offsetWidth; el.classList.add('open'); device.querySelector('.backdrop').classList.add('open');
  const first = el.querySelector('button:not([disabled])'); first && first.focus({ preventScroll: true });
}
function openAct(steps, opener) {
  const sh = $('#sheet-act'); if (!sh) return;
  sh.innerHTML = `<div class="grab"></div><div class="steps">${steps}</div>`;
  sh.classList.toggle('center', S.vp === 'desk');
  openEl('#sheet-act', opener);
  const af = sh.querySelector('.step:not([aria-hidden="true"]) [data-autofocus]'); af && af.focus({ preventScroll: true });
}
function showToast(msg) {
  const t = $('#toast'); t.querySelector('span').textContent = msg;
  void t.offsetWidth; t.classList.add('show'); setTimeout(() => t.classList.remove('show'), 2600);
}
function setTheme(v) { if (v === 'system') delete document.documentElement.dataset.theme; else document.documentElement.dataset.theme = v; }

/* ---- the phone soft keyboard (059/061 flagged this and it was never tested) ----
   A field taking focus opens the keyboard over the bottom of the screen. The tab bar leaves while
   that is true (it would otherwise be either hidden behind the keyboard on iOS or pressed against
   its top row on Android, where Estantes gets tapped instead of the space bar), and anything
   anchored to the bottom — an open sheet, the snackbar — sits on top of the keyboard instead of
   under it. On desktop none of this applies. */
const isField = el => el && el.matches('input:not([type=checkbox]):not([type=button]), textarea');
function setKbd(open) {
  if (KBD.open === open) return;
  KBD.open = open;
  device.classList.toggle('kbd', open);
  const sim = $('.kbdsim');
  if (open && !sim) device.insertAdjacentHTML('beforeend', '<div class="kbdsim" aria-hidden="true">TECLADO SIMULADO</div>');
  if (!open && sim) sim.remove();
  document.querySelectorAll('[data-kbd]').forEach(b => b.classList.toggle('on', b.dataset.kbd === (open ? '1' : '0')));
  if (open) keepFocusedInView();
}
/* the focused field must stay above the keyboard — otherwise you type into something you can't see */
function keepFocusedInView() {
  const a = document.activeElement; if (!isField(a) || !device.contains(a)) return;
  const sc = $('.scroller'), holder = a.closest('.sheet');
  if (holder) return;                                   /* sheets are lifted by CSS, not scrolled */
  const r = a.getBoundingClientRect(), d = device.getBoundingClientRect();
  const kb = parseInt(getComputedStyle(device).getPropertyValue('--kbh') || '292', 10);
  const floor = d.bottom - kb - 12;
  if (r.bottom > floor) sc.scrollBy({ top: r.bottom - floor, behavior: 'smooth' });
}
device.addEventListener('focusin', e => { if (isField(e.target) && S.vp !== 'desk') setKbd(true); });
device.addEventListener('focusout', e => {
  if (!isField(e.target)) return;
  setTimeout(() => { if (!isField(document.activeElement) || !device.contains(document.activeElement)) setKbd(false); else keepFocusedInView(); }, 0);
});

/* swipe a bottom sheet down to dismiss (phone) */
let drag = null, suppressClick = false;
device.addEventListener('pointerdown', e => {
  const sh = e.target.closest('.sheet.open'); if (!sh || S.vp === 'desk') return;
  if (!e.target.closest('.grab') && sh.scrollTop > 0) return;
  const onButton = e.target.closest('button') && !e.target.closest('.grab');
  drag = { sh, y: e.clientY, dy: 0, pending: !!onButton };
  if (!onButton) sh.classList.add('dragging');
});
window.addEventListener('pointermove', e => {
  if (!drag) return; const dy = Math.max(0, e.clientY - drag.y);
  if (drag.pending) { if (dy < 8) return; drag.pending = false; drag.sh.classList.add('dragging'); }
  drag.dy = dy; drag.sh.style.transform = `translateY(${dy}px)`;
});
window.addEventListener('pointerup', () => {
  if (!drag) return; const { sh, dy, pending } = drag; drag = null; sh.classList.remove('dragging');
  if (pending) return;
  if (dy > 8) { suppressClick = true; setTimeout(() => suppressClick = false, 0); }
  if (dy > 80) closeAll(); else sh.style.transform = '';
});

/* ---- the walk ---- */
const WALK = [
  { k: 'panel', label: 'Admin', run: () => go('panel') },
  { k: 'juegos', label: 'Juegos', run: () => go('juegos') },
  { k: 'editar', label: 'Editor', run: () => openEditor(J.games.find(g => g.bgg === 224517) || J.games[0]) },
  { k: 'juegos', label: '‹ Juegos', run: () => go('juegos') },
  { k: 'secciones', label: 'Web', run: () => go('secciones') },
  { k: 'seccion', label: 'sección', run: () => { V.cur = 1; V.ed = null; V.memQ = ''; go('seccion'); } },
  { k: 'estantes', label: 'Estantes', run: () => { V.listaQ = ''; resetGrps(); go('estantes'); } },
  /* 065 R8: the walk's 8th stop was Estantes › Asignar, a drill-down that no longer exists. What
     inherited its job is an EXPANDED estante on the same page, so the stop stays and the navigation
     goes away — which is the whole point of the round. */
  { k: 'estantes', label: 'Estante abierto', run: () => { V.listaQ = ''; resetGrps(); V.grpOpen.s1 = true; go('estantes'); } },
  { k: 'perfil', label: 'Perfil', run: () => { go('estantes'); setTimeout(() => openEl('#sheet-account', device.querySelector('[data-act="open-account"]')), 160); } },
];
let walkAt = -1;
function renderWalk() {
  const el = document.getElementById('walk'); if (!el) return;
  el.innerHTML = WALK.map((w, i) => `<button class="stab ${i === walkAt ? 'active' : i < walkAt ? 'done' : ''}" data-walk="${i}">${w.label}</button>`).join('')
    + `<button class="stab" data-walk="next" style="margin-left:6px">▶ Siguiente</button>`;
}

/* ---- ONE event layer ---- */
function markOn(attr, t) { document.querySelectorAll(`[${attr}]`).forEach(b => b.classList.toggle('on', b === t)); }
document.addEventListener('click', e => {
  if (suppressClick) { e.stopPropagation(); e.preventDefault(); return; }
  const t = e.target.closest('[data-walk],[data-kbd],[data-status],[data-bgg],[data-pend],[data-vp],[data-role],[data-theme-set],[data-act],[data-nav]');
  if (!t) return;
  /* --- sketch chrome --- */
  if (t.dataset.walk) {
    walkAt = t.dataset.walk === 'next' ? (walkAt + 1) % WALK.length : +t.dataset.walk;
    WALK[walkAt].run(); return renderWalk();
  }
  if (t.dataset.kbd) { const f = document.activeElement; if (t.dataset.kbd === '0' && isField(f)) f.blur(); return setKbd(t.dataset.kbd === '1'); }
  if (t.dataset.status) { seed(t.dataset.status); markOn('data-status', t); S.screen = 'editar'; closeAll(); return render(); }
  if (t.dataset.bgg) { E.failed = t.dataset.bgg === 'failed'; markOn('data-bgg', t); return patch(); }
  if (t.dataset.pend) {
    S.pend = t.dataset.pend === '1';
    Object.assign(V, seed062(S.pend), { ed: null, ordering: null, memQ: '', listaQ: '', memErr: null, invErr: null }); resetGrps();
    J.data = S.pend ? 'full' : 'nodrafts';
    if (!V.sections.some(s => s.id === V.cur)) V.cur = 1;
    if (!V.shelves.some(s => s.id === V.curShelf)) V.curShelf = 1;
    markOn('data-pend', t); return render();
  }
  if (t.dataset.vp) { S.vp = t.dataset.vp; if (t.dataset.vp === 'desk') setKbd(false); markOn('data-vp', t); return render(); }
  if (t.dataset.role) { S.role = t.dataset.role; if (S.screen === 'staff' && S.role !== 'owner') S.screen = 'panel'; markOn('data-role', t); return render(); }
  if (t.dataset.themeSet) return setTheme(t.dataset.themeSet);
  /* --- page actions, by their sketch's prefix --- */
  if (t.dataset.act && t.dataset.act.startsWith('v-')) return vAct(t);
  if (t.dataset.act && t.dataset.act.startsWith('e-')) return eAct(t);
  if (t.dataset.act && t.dataset.act.startsWith('j-')) {
    const a = t.dataset.act, g = J.games.find(x => x.id === +t.dataset.gameId);
    if (a === 'j-filter') { J.filter = t.dataset.f; refreshList(); $(`#jfilters [data-f="${J.filter}"]`)?.focus({ preventScroll: true }); }
    else if (a === 'j-clear') { J.q = ''; $('#q-in').value = ''; $('.sfield .clear').hidden = true; refreshList(); $('#q-in').focus(); }
    else if (a === 'j-more') { const add = POOL.splice(0, 6).map(([name, year, pl, hue]) => mk({ name, bgg: 1000 + gid, status: 'published', year, pl, hue })); J.games.push(...add); J.loaded += add.length; refreshList(); }
    else if (a === 'j-retry' && g) { g.enr = 'pending'; refreshList(); enrichLater(g); }
    else if (a === 'j-open' && g) return openEditor(g);        /* the walk's whole point: this really opens the editor */
    else if (a === 'j-cancel') { J.prompt = null; refreshAdd(); $('#add-in').focus(); }
    else if (a === 'j-confirm') { insertDraft(J.prompt.bgg); snack('Edición agregada como borrador'); }
    else if (a === 'j-sim-load') { if (S.screen !== 'juegos') { go('juegos'); } setTimeout(() => { J.loading = true; refreshList(); setTimeout(() => { J.loading = false; refreshList(); }, 1400); }, 120); }
    return;
  }
  /* --- navigation --- */
  if (t.dataset.nav) {
    const n = t.dataset.nav;
    const wasOpen = !!device.querySelector('.drawer.open,.sheet.open');
    if (n === 'pub:about') { closeAll(); return showToast('Quiénes Somos (sin cambios)'); }
    if (n === 'pub:inicio') { if (S.mode === 'out') { closeAll(); return; } S.mode = 'public'; closeAll(); return setTimeout(render, wasOpen ? 200 : 0); }
    if (t.dataset.tab && S.mode === 'admin' && activeTop() === n && S.screen === n) {
      return $('.scroller').scrollTo({ top: 0, behavior: 'smooth' });
    }
    if (S.mode !== 'admin') { S.mode = 'admin'; S.screen = n; closeAll(); return setTimeout(render, wasOpen ? 200 : 0); }
    return go(n);
  }
  /* --- shell --- */
  const a = t.dataset.act;
  if (a === 'open-drawer') openEl('.drawer', t);
  else if (a === 'open-account') openEl('#sheet-account', t);
  else if (a === 'ask-logout') setStep(t.closest('.sheet'), 'confirm');
  else if (a === 'cancel-logout') setStep(t.closest('.sheet'), 'account');
  else if (a === 'close') { E.pendingNav = null; closeAll(); }
  else if (a === 'logout') {
    t.disabled = true; t.querySelector('.slot').innerHTML = '<span class="spin"></span>'; t.querySelector('.lbl').textContent = 'Cerrando sesión…';
    t.closest('.dlinks').querySelectorAll('.dlink').forEach(b => { if (b !== t) b.disabled = true; });
    setTimeout(() => { closeAll(); setTimeout(() => { S.mode = 'out'; S.screen = 'panel'; S.toast = 'Cerraste sesión'; render(); }, 220); }, 550);
  }
  else if (a === 'login') { S.mode = 'admin'; S.screen = 'panel'; S.toast = 'Entraste como ' + USER.email; render(); }
});
document.addEventListener('keydown', e => {
  if (e.key !== 'Escape') return;
  const confirm = device.querySelector('.sheet.open .step-confirm:not([aria-hidden="true"])');
  if (confirm) setStep(confirm.closest('.sheet'), 'account'); else { E.pendingNav = null; closeAll(); }
});
document.addEventListener('focusout', e => {
  if (e.target.id === 'ed-desc' && E.descEdit) setTimeout(() => { if (document.activeElement?.id !== 'ed-desc') { E.descEdit = false; patch(); } }, 0);
});

let qTimer;
const V_FIELDS = { 'sec-new': ['newSec', 'newSecErr'], 'shelf-new': ['newShelf', 'newShelfErr'], 'inv-in': ['inv', 'invErr'] };
document.addEventListener('input', e => {
  const el = e.target, id = el.id;
  /* --- 063 editor --- */
  if (S.screen === 'editar') {
    const clearErr = k => { if (!E.errs[k]) return; delete E.errs[k]; el.classList.remove('invalid'); el.removeAttribute('aria-invalid'); const f = document.getElementById(`ed-${k}-err`); if (f) f.textContent = ''; };
    if (id === 'ed-name') { E.ed.name = el.value; el.closest('.tfield').dataset.value = el.value || 'Nombre del juego'; clearErr('name'); return sync(); }
    if (id === 'ed-desc') { E.ed.desc = el.value; return sync(); }
    if (id === 'ed-exp') { E.ed.exp = el.checked; return sync(); }
    if (el.dataset.sec) {
      const sid = +el.dataset.sec, s = MANUAL.find(x => x.id === sid);
      if (el.checked && s.featured && featBase() + 1 > 20) { el.checked = false; E.secErr = 'Destacados del club ya tiene 20 juegos. Quitá uno desde Web para sumar este.'; return refreshSecs(id); }
      E.ed.secs = el.checked ? [...E.ed.secs, sid] : E.ed.secs.filter(x => x !== sid); E.secErr = null;
      return refreshSecs(id);
    }
  }
  /* --- 062 lists --- */
  if (V_FIELDS[id]) { const [k, err] = V_FIELDS[id]; V[k] = el.value; V[err] = null; return patch(); }
  if (QMAP[id]) {
    V[QMAP[id]] = el.value; if (id === 'mem-q') V.memErr = null; if (id === 'lista-q') resetGrps();
    const c = el.parentElement.querySelector('.clear'); if (c) c.hidden = !el.value;
    clearTimeout(qTimer); qTimer = setTimeout(() => refreshQ(id), 300); return;
  }
  if (V.ed && id === 'ed-name') { V.ed.name = el.value; return syncSecBar(); }
  if (V.ed && id === 'ed-sub') { V.ed.sub = el.value; return syncSecBar(); }
  if (V.ed && id === 'ed-sort') { V.ed.sort = el.value; return syncSecBar(); }
  if (V.ed && id === 'ed-show') { V.ed.hidden = !el.checked; return patch(); }
  if (id === 'ren-in') { V.ren = el.value; if (V.renErr) { V.renErr = null; el.classList.remove('invalid'); const f = el.closest('form').querySelector('.ferr'); if (f) f.textContent = ''; } return; }
  /* --- 061 Juegos --- */
  if (id === 'add-in') { J.add = el.value; if (J.err || J.prompt) { J.err = null; J.prompt = null; } return refreshAdd(); }
  if (id === 'q-in') { J.q = el.value; $('.sfield .clear').hidden = !J.q; clearTimeout(qTimer); qTimer = setTimeout(refreshList, 300); }
});
document.addEventListener('submit', e => {
  e.preventDefault();
  if (['ren-form', 'sec-new-form', 'shelf-new-form', 'inv-in-form'].includes(e.target.id)) return submitV(e.target.id);
  if (e.target.id === 'add-form') return submitAdd();
});
document.getElementById('tools-toggle').addEventListener('click', () => document.getElementById('tools-body').classList.toggle('show'));

const NOTES = `<h3>Sketch 065 · el admin completo, compuesto</h3><ul>
  <li><b>No es un rediseño.</b> El CSS es el de 063 y cada página viene entera de su sketch (060 Admin, 061 Juegos, 062 Web/Estantes/Asignar/Niveles/Staff, 063 editor). <code>build.js</code> los recorta de los archivos originales: si acá algo se ve mal, se arregla en el sketch de origen y se vuelve a generar.</li>
  <li><b>El recorrido</b> de la barra de arriba camina Admin → Juegos → editor → ‹ Juegos → Web → sección → Estantes → Asignar → Perfil, que es lo que esta hoja viene a revisar.</li>
  <li><b>Estantes (R9):</b> <i>tools → Estantes (R9)</i> cambia entre <b>A</b> (la lista de la ronda 8, la que ganó), <b>B</b> (los juegos del estante como riel horizontal) y <b>C</b> (riel como mapa sobre la lista). Abrí <i>Estante D — expertos</i> (162 cajas) y probá llegar al medio; después buscá <code>dixit</code> y tocá la fila.</li>
  <li><b>Teclado:</b> tocá cualquier campo (o <i>tools → Teclado</i>) para ver qué pasa con la barra de pestañas, con una hoja abierta y con el título y la descripción del editor.</li></ul>`;

S.screen = 'panel';
render();
