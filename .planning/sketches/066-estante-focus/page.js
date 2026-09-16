/* ================= 066: estante focus ================= */
(function () {
  const root = document.documentElement;
  /* round 1 (focus on expand) is kept switchable; round 2 (master/detail) is the default */
  root.dataset.e066 = 'r2a';
  const R2 = () => root.dataset.e066.startsWith('r2');
  const reduce = matchMedia('(prefers-reduced-motion: reduce)');
  const openKeys = () => Object.keys(V.grpOpen).filter(k => V.grpOpen[k]);
  let before = null;
  document.addEventListener('click', e => {
    const f = e.target.closest('button[data-e066]');
    if (f) {
      const v = f.dataset.e066; root.dataset.e066 = v;
      if (v.startsWith('r1')) root.dataset.foco = v.slice(2); else delete root.dataset.foco;
      document.querySelectorAll('button[data-e066]').forEach(b => b.classList.toggle('on', b === f));
      e.stopImmediatePropagation();
      resetGrps(); runway(0); if (S.screen === 'estante') go('estantes'); else patch();
      return;
    }
    const o = e.target.closest('#device [data-act="v066-open"]');
    if (o) { e.stopImmediatePropagation(); openEstante(o.dataset.sid); return; }
    before = S.screen === 'estantes' ? openKeys() : null;
  }, true);
  /* registered after 065's document listener, so it runs after the row has opened and patched */
  document.addEventListener('click', () => {
    if (!before || !root.dataset.foco || R2()) return;
    const now = openKeys(), fresh = now.filter(k => !before.includes(k));
    before = null;
    if (!fresh.length) { if (!now.length) runway(0); return; }
    const k = fresh[fresh.length - 1];
    let closed = false;
    for (const o of now) if (o !== k) { V.grpOpen[o] = false; delete V.grpShown[o]; closed = true; }
    if (closed) { V.gameOpen = null; if (V.adding != null && 's' + V.adding !== k) V.adding = null; if (V.ordering && 's' + V.ordering.slice(2) !== k) V.ordering = null; patch(); }
    requestAnimationFrame(() => focusTo(k));
  });
  function runway(px) { const m = device.querySelector('main'); if (m) m.style.paddingBottom = px ? px + 'px' : ''; }
  function focusTo(k) {
    const sc = device.querySelector('.scroller'), row = device.querySelector('main [data-grp="' + k + '"]');
    if (!sc || !row) return;
    const hdr = device.querySelector('header'), hh = hdr ? hdr.offsetHeight : 0;
    runway(0);
    const y = row.getBoundingClientRect().top - sc.getBoundingClientRect().top + sc.scrollTop - hh;
    /* main has a min-height, so padding it is partly absorbed: grow the runway until the scroll reaches */
    let pad = 0;
    for (let i = 0; i < 6; i++) { const short = Math.ceil(y - (sc.scrollHeight - sc.clientHeight)); if (short <= 0) break; pad += short; runway(pad); }
    const short = pad;
    sc.scrollTo({ top: y, behavior: reduce.matches ? 'auto' : 'smooth' });
    window.__066last = { k, y: Math.round(y), runway: Math.max(0, short) };
  }
  window.__066focus = focusTo;

  /* ---- round 2: master/detail ---- */
  SCREENS.estante = { title: 'Estante', parent: 'estantes' };
  const baseShelf = window.grpShelf, baseSin = window.grpSin, baseBody = window.adminBody;
  let listTop = 0;
  const drill = (sid, name, sub, icon) => `<button type="button" class="grow disclose drill" data-key="e${sid}" data-act="v066-open" data-sid="${sid}">${slotIco(icon)}${txt(name, sub)}${ic('chevR', 'chev')}</button>`;
  window.grpShelf = sh => R2() ? `<div class="grp"><div class="glist">${drill(sh.id, esc(sh.name), meta(`${nf(shelfCount(sh))} juegos`), 'estantes')}</div></div>` : baseShelf(sh);
  window.grpSin = () => { if (!R2()) return baseSin(); const n = unplacedN();
    return `<section class="jsec grp"><div class="glist">${drill('sin', 'Sin ubicar', meta(n ? `${nf(n)} juegos` : 'ninguno'), 'niveles')}</div></section>`; };
  function openEstante(sid) {
    if (S.screen === 'estantes') listTop = device.querySelector('.scroller').scrollTop;
    V.est066 = sid; V.grpOpen = { [sid === 'sin' ? 'sin' : 's' + sid]: true }; V.grpShown = {};
    V.tileOn = null; V.adding = null; V.ordering = null; V.gameOpen = null;
    go('estante');
  }
  window.openEstante = openEstante;
  function nextOf(sid) { const i = V.shelves.findIndex(x => String(x.id) === String(sid)); return i >= 0 ? V.shelves[i + 1] : null; }
  function estanteBody() {
    const sid = V.est066;
    if (sid === 'sin') {
      const n = unplacedN(), shown = unplacedLocal().slice(0, V.grpShown.sin || GRP_PAGE);
      return `${head('Sin ubicar', { parent: 'estantes', sub: n ? `${nf(n)} juegos sin estante` : 'Todos los juegos tienen estante' })}
        <section class="jsec"><div class="glist">${shown.map(g => estGameRow(g, null)).join('')}</div>
        ${shown.length < n ? moreRow('v-grp-more', 'data-grp="sin"', shown.length, n) : ''}</section>`;
    }
    const sh = shelfById(+sid); if (!sh) return head('Estante', { parent: 'estantes' });
    V.grpOpen = { ['s' + sh.id]: true };
    let blk = baseShelf(sh).replace(/<button type="button" class="grow disclose"[\s\S]*?<\/button>/, '').replace('<div class="glist"></div>', '');
    /* a new estante has no boxes: say so, instead of 065's "Tocá una caja" over an empty rail */
    if (!shelfCount(sh) && V.adding !== sh.id) blk = blk.replace(/<div class="erail-wrap"[\s\S]*?<p class="lnote gnote grail">[^<]*<\/p>/, '<p class="lnote gnote grail">Todavía no tiene juegos. Agregalos en el orden del estante, de izquierda a derecha.</p>');
    const nx = root.dataset.e066 === 'r2b' && V.adding !== sh.id && V.ordering !== 'sh' + sh.id ? nextOf(sh.id) : null;
    return `${head(esc(sh.name), { parent: 'estantes', sub: `${nf(shelfCount(sh))} juegos` })}
      <section class="jsec est-detail">${blk}</section>
      ${nx ? `<section class="jsec est-next"><div class="lhead"><span class="group-label">Siguiente estante</span></div>
        <div class="glist">${drill(nx.id, esc(nx.name), meta(`${nf(shelfCount(nx))} juegos`), 'estantes')}</div></section>` : ''}`;
  }
  window.adminBody = () => S.screen === 'estante' ? estanteBody() : baseBody();
  /* round 2 decision: Crear lands on the new estante's page. In the start-empty walk (D-05, D-09) the
     next estante never exists yet, so this — not a Siguiente link — is what shortens the walk. */
  const baseSubmit = window.submitV;
  window.submitV = id => {
    const n = V.shelves.length, r = baseSubmit(id);
    if (id === 'shelf-new-form' && R2() && V.shelves.length > n) {
      const sh = V.shelves[V.shelves.length - 1];
      openEstante(String(sh.id));
      snack('Estante creado');
    }
    return r;
  };
  /* back to the list lands where you left it (iOS/M3 both keep the master's scroll) */
  const baseGo = window.go;
  window.go = target => { const from = S.screen; baseGo(target);
    if (from === 'estante' && target === 'estantes' && R2()) setTimeout(() => { const sc = device.querySelector('.scroller'); if (sc) sc.scrollTop = listTop; }, 140); };

  /* 19a: pinned twin of a dirty save bar, shown only while the in-page bar is off screen */
  function pin() {
    let tw = device.querySelector('.ebar-pin');
    const bar = [...device.querySelectorAll('main .ebar.inline')].find(e => e.querySelector('.eactions > :is(.obtn, .b-pri, .b-sec)'));
    const sc = device.querySelector('.scroller'), tabs = device.querySelector('.tabs');
    if (!bar || !sc || S.vp === 'desk') { if (tw) tw.remove(); return; }
    const r = bar.getBoundingClientRect(), s = sc.getBoundingClientRect();
    const floor = tabs && !device.classList.contains('kbd') ? tabs.getBoundingClientRect().top : s.bottom;
    const inView = r.top >= s.top + 53 && r.bottom <= floor - 12;
    if (inView) { if (tw) tw.remove(); return; }
    if (!tw) { device.insertAdjacentHTML('beforeend', '<div class="ebar inline ebar-pin" role="region" aria-label="Cambios sin guardar"></div>'); tw = device.querySelector('.ebar-pin'); }
    if (tw.innerHTML !== bar.innerHTML) tw.innerHTML = bar.innerHTML;
  }
  device.addEventListener('scroll', pin, true);
  new MutationObserver(() => requestAnimationFrame(pin)).observe(device, { childList: true, subtree: true, characterData: true });
  document.addEventListener('input', () => requestAnimationFrame(pin));

  /* 19c: every toast message is a plain snackbar */
  window.showToast = msg => snack(msg);
  /* 19b: action snackbars stay 10 s and carry a ✕; plain ones keep 4 s */
  const base = window.snack;
  window.snack = function (msg, action) {
    base(msg, action);
    const s = document.getElementById('snack'); if (!s) return;
    let x = s.querySelector('.snack-x');
    if (!x) { s.insertAdjacentHTML('beforeend', '<button class="snack-x" aria-label="Cerrar aviso">' + ic('x') + '</button>'); x = s.querySelector('.snack-x'); x.addEventListener('click', ev => { ev.stopPropagation(); clearTimeout(s._t); s.classList.remove('show'); }); }
    x.hidden = !action;
    clearTimeout(s._t);
    s._t = setTimeout(() => s.classList.remove('show'), action ? 10000 : 4000);
  };
})();
