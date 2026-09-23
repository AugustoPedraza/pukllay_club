/* ================= 068: locate a box ================= */
(function () {
  const root = document.documentElement;
  root.dataset.r068 = 'a';
  const BASE = 5000;
  const mine = () => G.filter(g => g.id >= BASE);
  const shelfOf = sid => V.shelves.find(s => s.id === sid);
  function where(g) {
    const sid = V.place[g.id], a = V.order[sid] || [], i = a.indexOf(g.id);
    return { sid, i, n: a.length, sh: shelfOf(sid), prev: i > 0 ? gById(a[i - 1]) : null, next: i >= 0 && i < a.length - 1 ? gById(a[i + 1]) : null };
  }
  const cover = (g, cls) => g.thumb ? `<img class="${cls} r068-img" src="${g.thumb}" alt="" loading="lazy">`
    : `<span class="${cls} r068-letter" style="--h:${g.hue}" aria-hidden="true">${esc(g.name[0])}</span>`;
  const between = w => w.prev && w.next ? `entre <b>${esc(w.prev.name)}</b> y <b>${esc(w.next.name)}</b>`
    : w.prev ? `al final, después de <b>${esc(w.prev.name)}</b>` : w.next ? `al principio, antes de <b>${esc(w.next.name)}</b>` : 'es la única caja';
  const betweenTxt = w => between(w).replace(/<\/?b>/g, '');
  /* where along the shelf, drawn: a track with its two physical ends named. The number says exactly
     which box; the bar says where to walk to. It replaces the three zone WORDS as the "where" cue. */
  const bar = w => `<span class="r068-barwrap" aria-hidden="true"><span class="r068-end">Izq.</span><span class="r068-bar"><i style="left:${w.n > 1 ? (w.i / (w.n - 1) * 100).toFixed(1) : 50}%"></i></span><span class="r068-end">Der.</span></span>`;
  const place = w => `${esc(w.sh.name)} · caja ${w.i + 1} de ${w.n}`;

  function hitA(g) {
    const w = where(g);
    return `<button type="button" class="grow r068-hit" data-act="v068-go" data-id="${g.id}" aria-label="${esc(g.name)}: ${esc(place(w))}, ${esc(betweenTxt(w))}. Ver en el estante">
      ${cover(g, 'thumb')}<span class="gtxt"><span class="gname">${esc(g.name)}</span>
      <span class="r068-place">${esc(place(w))}</span><span class="r068-nbr">${between(w)}</span>${bar(w)}</span>${ic('chevR', 'chev')}</button>`;
  }
  const nbrTile = (g, label, on) => g ? `<span class="r068-nt ${on ? 'on' : ''}">${cover(g, 'r068-ncov')}<span class="r068-ncap">${esc(g.name)}</span><span class="r068-nlab">${label}</span></span>`
    : `<span class="r068-nt empty"><span class="r068-ncov r068-edge">${label === 'a la izquierda' ? 'Principio' : 'Final'}<br>del estante</span></span>`;
  function hitB(g) {
    const w = where(g), open = V.r068open === g.id;
    return `<div class="r068-bwrap ${open ? 'open' : ''}"><button type="button" class="grow r068-hit b" data-act="v068-exp" data-id="${g.id}" aria-expanded="${open}">
      ${cover(g, 'thumb')}<span class="gtxt"><span class="gname">${esc(g.name)}</span><span class="r068-place">${esc(place(w))}</span></span>${ic('chevR', 'chev')}</button>
      ${open ? `<div class="r068-card">
        <div class="r068-nbrs">${nbrTile(w.prev, 'a la izquierda')}${nbrTile(g, 'esta caja', true)}${nbrTile(w.next, 'a la derecha')}</div>
        ${bar(w)}
        <div class="r068-cacts"><button type="button" class="tbtn" data-act="v068-go" data-id="${g.id}">Ver en el estante</button></div>
      </div>` : ''}</div>`;
  }
  function groups() {
    const q = norm(V.listaQ.trim());
    if (!q) return shelves();
    const rs = mine().filter(g => norm(g.name).includes(q));
    if (!rs.length) return `<section class="jsec"><div class="empty">${ic('search')}<h2>Sin resultados para “${esc(V.listaQ)}”</h2>
      <button type="button" class="tbtn" data-act="v-clear" data-for="lista-q">Borrar búsqueda</button></div></section>`;
    const shown = rs.slice(0, 20);
    return `<section class="jsec"><div class="lhead"><span class="group-label">Resultados</span><span class="gcount">${rs.length}</span></div>
      <div class="glist">${shown.map(root.dataset.r068 === 'b' ? hitB : hitA).join('')}</div>
      ${rs.length > shown.length ? `<p class="lnote">Mostrando 20 de ${rs.length}. Escribí un poco más.</p>` : ''}</section>`;
  }
  const count = sid => V.order[sid].length;
  const drill = s => `<button type="button" class="grow disclose drill" data-key="e${s.id}" data-act="v066-open" data-sid="${s.id}">${slotIco('estantes')}${txt(esc(s.name), meta(`${count(s.id)} cajas`))}${ic('chevR', 'chev')}</button>`;
  function shelves() {
    const total = V.shelves.reduce((a, s) => a + count(s.id), 0);
    return `<section class="jsec"><div class="lhead"><span class="group-label">Estantes del club</span><span class="gcount">${nf(total)} cajas</span></div>
      ${V.shelves.map(s => `<div class="grp"><div class="glist">${drill(s)}</div></div>`).join('')}</section>`;
  }
  QREG['lista-q'] = ['est-groups', groups];
  function listBody() {
    return `${head('Estantes')}${sfield('lista-q', 'Buscar un juego', V.listaQ)}<div style="height:16px"></div><div id="est-groups">${groups()}</div>`;
  }

  /* the selected box on the estante page: no second copy of the name (the tile's caption has it), the
     answer in one line, and the rare actions behind ONE text action that opens a sheet. */
  const baseEPanel = window.ePanel;
  window.ePanel = (sid, slot) => {
    if (V.ordering === 'sh' + sid) return baseEPanel(sid, slot);
    const g = gById(ordOf(sid)[slot]); if (!g) return '';
    const w = where(g);
    return `<div class="r068-sel" aria-live="polite"><p class="r068-selline"><b>Caja ${w.i + 1} de ${w.n}</b> · ${between(w)}</p>${bar(w)}
      <div class="r068-selacts"><button type="button" class="tbtn" data-act="v068-opts" data-id="${g.id}" aria-haspopup="dialog">Opciones de la caja</button></div></div>`;
  };

  const base067 = window.adminBody;
  window.adminBody = () => S.screen === 'estantes' ? listBody() : base067();

  function goTo(id) {
    const g = gById(id), w = where(g);
    openEstante(String(w.sid));
    V.tileOn = { sid: w.sid, slot: w.i };
    setTimeout(() => { railTo(w.sid, w.i, { smooth: false }); document.querySelector(`#device .etile[data-sid="${w.sid}"][data-slot="${w.i}"]`)?.focus({ preventScroll: true }); }, 220);
  }
  document.addEventListener('click', e => {
    const f = e.target.closest('button[data-r068]');
    if (f) { root.dataset.r068 = f.dataset.r068; V.r068open = null;
      document.querySelectorAll('button[data-r068]').forEach(b => b.classList.toggle('on', b === f));
      e.stopImmediatePropagation(); return S.screen === 'estantes' ? patch() : go('estantes'); }
    const t = e.target.closest('#device [data-act^="v068-"]'); if (!t) return;
    e.stopImmediatePropagation();
    const id = +t.dataset.id, act = t.dataset.act;
    if (act === 'v068-go') return goTo(id);
    if (act === 'v068-exp') { V.r068open = V.r068open === id ? null : id; return refreshQ('lista-q'); }
    if (act === 'v068-opts') { const g = gById(id), w = where(g);
      return openAct(`<div class="step step-account"><div class="group-label r068-sheet-t">${esc(g.name)}</div><p class="sheet-text">${esc(place(w))}</p><div class="dlinks">
        ${row({ act: 'v-view-game', extra: `data-id="${g.id}"`, icon: 'juegos', label: 'Ver en la ludoteca', chev: false })}
        ${row({ act: 'v068-soon', extra: 'data-id="0" data-what="Mover"', icon: 'bars', label: 'Mover a otro lugar', sub: 'Boceto 070', chev: false })}
        ${row({ act: 'v-rm-shelf', extra: `data-id="${g.id}" data-sid="${w.sid}"`, icon: 'x', label: 'Quitar del estante', tone: 'danger', chev: false })}
        ${row({ act: 'v-close', icon: 'chevL', label: 'Cancelar', chev: false })}</div></div>`, t); }
    if (act === 'v068-soon') { closeAll(); return snack('Mover se dibuja en el boceto 070'); }
  }, true);

  S.screen = 'estantes';
})();
