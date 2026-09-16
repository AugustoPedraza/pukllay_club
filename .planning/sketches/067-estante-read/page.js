/* ================= 067: read an estante (01.8.2 D-22, workflow 1) ================= */
(function () {
  const root = document.documentElement;
  root.dataset.r067 = 'c';            // developer: the rail stays, with covers and clipped names
  root.dataset.e066 = 'r2a';            // master/detail from 066 is the frame
  /* the club's real shape (developer, 2026-09-16): 9 horizontal estantes, the fullest holds up to 50 */
  const SIZES = [50, 50, 49, 48, 48, 48, 48, 47, 46];
  const hue = s => { let h = 0; for (const c of s) h = (h * 31 + c.charCodeAt(0)) % 360; return h; };
  const base = 5000;
  GAMES067.forEach((x, i) => G.push({ id: base + i, name: x.n, year: x.y, thumb: x.t, status: 'published', hue: hue(x.n), pl: '' }));
  V.shelves = SIZES.map((n, i) => ({ id: i + 1, name: 'Estante ' + (i + 1), base: 0 }));
  V.order = {}; let k = 0;
  SIZES.forEach((n, i) => { V.order[i + 1] = Array.from({ length: n }, () => base + k++); });
  G.forEach(g => { if (g.id >= base) V.place[g.id] = V.shelves.find(s => V.order[s.id].includes(g.id)).id; });
  V.hiddenUnplaced = 0;

  const mode = () => root.dataset.r067;
  /* covers, as the app shows them; the letter tile is the app's fallback for the 49 games without one */
  const cover = (g, cls) => g.thumb ? `<img class="${cls} r067-img" src="${g.thumb}" alt="" loading="lazy" onerror="this.replaceWith(Object.assign(document.createElement('span'),{className:'${cls}',textContent:'${esc(g.name[0])}'}))">` : `<span class="${cls}" style="--h:${g.hue}" aria-hidden="true">${esc(g.name[0])}</span>`;
  const count = sid => V.order[sid].length;
  const drill = (sid, name, sub, icon) => `<button type="button" class="grow disclose drill" data-key="e${sid}" data-act="v066-open" data-sid="${sid}">${slotIco(icon)}${txt(name, sub)}${ic('chevR', 'chev')}</button>`;

  /* the list page: nothing here is this round's question, so it carries only what reading needs */
  function listBody() {
    const total = V.shelves.reduce((a, s) => a + count(s.id), 0);
    return `${head('Estantes')}
      <section class="jsec"><div class="lhead"><span class="group-label">Estantes del club</span><span class="gcount">${nf(total)} cajas</span></div>
      ${V.shelves.map(s => `<div class="grp"><div class="glist">${drill(s.id, esc(s.name), meta(`${count(s.id)} cajas`), 'estantes')}</div></div>`).join('')}</section>`;
  }

  function listA(sh, ids) {
    return `<section class="jsec"><div class="lhead"><span class="group-label">De izquierda a derecha</span></div>
      <ol class="glist r067-list" aria-label="${esc(sh.name)}, de izquierda a derecha">
      ${ids.map((id, i) => { const g = gById(id);
        return `<li class="grow r067-row"><span class="r067-pos" aria-hidden="true">${i + 1}</span>${g.thumb ? cover(g, 'thumb') : thumbOf(g)}<span class="gtxt"><span class="gname">${esc(g.name)}</span></span><span class="sr">, caja ${i + 1} de ${ids.length}</span></li>`; }).join('')}
      </ol><p class="lnote r067-end">Derecha: fin del estante.</p></section>`;
  }
  function gridB(sh, ids) {
    return `<section class="jsec"><div class="lhead"><span class="group-label">De izquierda a derecha</span></div>
      <ol class="r067-grid" aria-label="${esc(sh.name)}, de izquierda a derecha">
      ${ids.map((id, i) => { const g = gById(id);
        return `<li class="r067-cell"><span class="r067-boxwrap">${cover(g, 'r067-box')}<span class="r067-num" aria-hidden="true">${i + 1}</span></span><span class="r067-name">${esc(g.name)}</span><span class="sr">, caja ${i + 1} de ${ids.length}</span></li>`; }).join('')}
      </ol><p class="lnote r067-end">Derecha: fin del estante.</p></section>`;
  }
  function estanteBody() {
    const sh = V.shelves.find(s => String(s.id) === String(V.est066)); if (!sh) return head('Estante', { parent: 'estantes' });
    const ids = V.order[sh.id];
    return `${head(esc(sh.name), { parent: 'estantes', sub: `${ids.length} cajas` })}${mode() === 'b' ? gridB(sh, ids) : listA(sh, ids)}`;
  }

  /* the rail keeps 065's anatomy; its letter tile becomes the cover (developer: "use image since it's
     recognizable"). The caption is already clamped to two lines with an ellipsis. */
  const baseRail = window.railHtml;
  window.railHtml = (sid, o) => baseRail(sid, o).replace(/(data-slot="(\d+)"[\s\S]*?<span class="ecover" style="--h:[\d.]+">)([^<]*)(<span class="emark">)/g,
    (m, pre, slot, letter, mark) => { const g = gById(ordOf(sid)[+slot]); return g && g.thumb ? pre + `<img class="ecover-img" src="${g.thumb}" alt="" loading="lazy">` + mark : m; });

  const base066 = window.adminBody;
  window.adminBody = () => {
    if (mode() === 'c') return base066();            // 065's rail + zone bar, on the same 9 estantes
    if (S.screen === 'estantes') return listBody();
    if (S.screen === 'estante') return estanteBody();
    return base066();
  };

  document.addEventListener('click', e => {
    const f = e.target.closest('button[data-r067]'); if (!f) return;
    root.dataset.r067 = f.dataset.r067;
    document.querySelectorAll('button[data-r067]').forEach(b => b.classList.toggle('on', b === f));
    e.stopImmediatePropagation();
    if (S.screen === 'estante') { const sid = V.est066; openEstante(String(sid)); } else patch();
  }, true);

  S.screen = 'estantes';
})();
