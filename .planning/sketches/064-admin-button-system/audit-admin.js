/* Cross-sketch audit: every admin sketch (059–063) follows the 064 button system (S3 Contorno, weight-tuned).
   Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/064-admin-button-system/audit-admin.js
   For each screen × light/dark it checks every visible action button (.obtn / .tbtn / .b-pri / .b-sec, snackbar action excluded):
     44px tall · 8px radius · 14px/600 · not disabled · outlined roles 1px stroke, text roles none · label ≥ 4.5:1
     at most one Principal per action row, and it is the last button in that row · text fields 1px stroke ≥ 3:1
   Also: every visible element declares weight 400 or 600 (the only Inter faces the app ships) and text renders in Inter/Bebas Neue.
   Env: PLAYWRIGHT_CORE, BASE (default http://127.0.0.1:8765/.planning/sketches/), SHOTS_DIR (default <tmp>/admin-button-audit). */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();
const BASE = process.env.BASE || 'http://127.0.0.1:8765/.planning/sketches/';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'admin-button-audit'); fs.mkdirSync(OUT, { recursive: true });
/* screens: [name, page-side setup code run before the audit] */
const SCREENS = {
  '059-admin-shell': [['admin', ''], ['login', "S.mode='out'; render();"]],
  '060-admin-panel-entries': [['admin', ''], ['login', "S.mode='out'; render();"]],
  '061-admin-juegos-page': [['juegos', ''], ['juegos-edition-prompt', "const g=J.games.find(x=>x.enr==='ok'); J.add=String(g.bgg); J.prompt={ bgg: g.bgg, games: [g] }; render();"], ['login', "S.mode='out'; render();"]],
  /* 065 R8: `asignar` is retired as a screen, so its two entries here re-point at the surface that
     inherited its job — an EXPANDED estante on the Estantes page — instead of being dropped: one for
     the estante open with its action strip, one for the estante open in "agregar juegos" mode. The
     rename sheet now opens from the estante's own options sheet, and "Nuevo estante" is a sheet too. */
  '062-admin-list-rows': [['web', "S.screen='secciones'; render();"], ['estantes', "S.screen='estantes'; render();"],
    ['estante-abierto', "S.screen='estantes'; V.listaQ=''; V.ordering=null; V.adding=null; resetGrps(); V.grpOpen.s1=true; render();"],
    ['estante-agregando', "S.screen='estantes'; V.listaQ=''; V.ordering=null; V.adding=null; resetGrps(); V.grpOpen.s1=true; V.adding=1; V.addShown=8; render();"],
    ['estante-ordenando', "S.screen='estantes'; V.listaQ=''; V.ordering=null; V.adding=null; resetGrps(); V.grpOpen.s1=true; V.ordering='sh1'; render();"],
    ['niveles', "S.screen='niveles'; render();"], ['staff', "S.screen='staff'; render();"], ['staff-invite-empty', "S.screen='staff'; render(); document.querySelector('#inv-in-form [type=submit]').click();"],
    ['rename-sheet', "S.screen='estantes'; V.listaQ=''; V.ordering=null; V.adding=null; resetGrps(); V.grpOpen.s1=true; render(); document.querySelector('[data-act=\"v-shelf-sheet\"][data-id=\"1\"]').click(); setTimeout(()=>document.querySelector('[data-act=\"v-rename\"]').click(), 120);"],
    ['nuevo-estante-sheet', "S.screen='estantes'; V.listaQ=''; V.ordering=null; V.adding=null; resetGrps(); render(); document.querySelector('[data-act=\"v-new-shelf\"]').click();"],
    ['seccion-dirty', "S.screen='seccion'; render(); const i=document.getElementById('ed-name'); if (i) { i.value += ' 2'; i.dispatchEvent(new Event('input', {bubbles:true})); }"]],
  '063-admin-game-editor': [
    ['draft-clean', "document.querySelector('[data-status=\"draft\"]').click();"],
    ['draft-dirty', "document.querySelector('[data-status=\"draft\"]').click(); const i=document.getElementById('ed-name'); i.value='Brass (ES)'; i.dispatchEvent(new Event('input',{bubbles:true}));"],
    ['published-clean', "document.querySelector('[data-status=\"published\"]').click();"],
    ['published-dirty', "document.querySelector('[data-status=\"published\"]').click(); document.getElementById('u-set1').click();"],
    ['retired-dirty', "document.querySelector('[data-status=\"retired\"]').click(); document.getElementById('u-set1').click();"],
    ['bgg-failed', "document.querySelector('[data-status=\"published\"]').click(); document.querySelector('[data-bgg=\"failed\"]').click();"]],
};
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);
(async () => {
  const b = await chromium.launch({ channel: 'chrome', headless: true });
  for (const [sketch, screens] of Object.entries(SCREENS)) {
    const p = await b.newPage({ viewport: { width: 1000, height: 1000 } });
    const errs = []; p.on('pageerror', e => errs.push(e.message));
    await p.goto(BASE + sketch + '/index.html'); await p.evaluate(() => document.fonts.ready);
    for (const theme of ['light', 'dark']) for (const [name, setup] of screens) {
      await p.evaluate(([setup, theme]) => { theme === 'dark' ? document.documentElement.dataset.theme = 'dark' : delete document.documentElement.dataset.theme; window.__setupErr = null; try { (0, eval)(setup); } catch (e) { window.__setupErr = e.message; } }, [setup, theme]);
      await p.waitForTimeout(350);
      await p.evaluate(() => { const d = document.getElementById('device'); d.scrollTop = d.scrollLeft = 0; });  /* sketch-frame artifact: focus can scroll the overflow:hidden device and uncover off-screen sheets */
      const a = await p.evaluate(() => {
        const rgb = s => { const srgb = /^color\(srgb/.test(s); const m = s.replace(/^color\(srgb/, '').match(/[\d.]+/g).map(Number); const k = srgb ? 255 : 1; return { r: m[0] * k, g: m[1] * k, b: m[2] * k, a: srgb ? (/\//.test(s) ? m[3] : 1) : (m[3] ?? 1) }; };
        const lum = c => [c.r, c.g, c.b].map(v => { v /= 255; return v <= .03928 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4; }).reduce((s, v, i) => s + v * [.2126, .7152, .0722][i], 0);
        const cr = (x, y) => { const L1 = lum(x), L2 = lum(y); return (Math.max(L1, L2) + .05) / (Math.min(L1, L2) + .05); };
        const bgOf = el => { const st = []; for (let n = el; n; n = n.parentElement) { const c = rgb(getComputedStyle(n).backgroundColor); if (c.a > 0) { st.push(c); if (c.a === 1) break; } } let base = { r: 255, g: 255, b: 255 }; for (const c of st.reverse()) base = { r: c.r * c.a + base.r * (1 - c.a), g: c.g * c.a + base.g * (1 - c.a), b: c.b * c.a + base.b * (1 - c.a) }; return base; };
        const vis = el => { const r = el.getBoundingClientRect(); if (!r.width || !r.height) return false; for (let n = el; n && n !== document.body; n = n.parentElement) { const cs = getComputedStyle(n); if (cs.visibility === 'hidden' || cs.display === 'none' || +cs.opacity === 0) return false; if (n.matches('.sheet:not(.open), .drawer:not(.open), [inert], [aria-hidden="true"]')) return false; } return true; };
        const dev = document.getElementById('device');
        const btns = [...dev.querySelectorAll('.obtn, .tbtn, .b-pri, .b-sec')].filter(el => !el.closest('.snack') && vis(el));
        const role = el => el.matches('.obtn, .b-pri') ? 'pri' : el.matches('.b-sec') ? 'sec' : el.matches('.danger') ? 'dan' : 'ter';
        const bad = [];
        for (const el of btns) {
          const cs = getComputedStyle(el), r = el.getBoundingClientRect(), R = role(el), label = el.textContent.trim() || el.getAttribute('aria-label');
          const bw = parseFloat(cs.borderTopWidth) * (cs.borderTopStyle === 'none' ? 0 : 1);
          if (Math.round(r.height) !== 44) bad.push(`${label}: height ${Math.round(r.height)}`);
          if (cs.borderTopLeftRadius !== '8px' && !el.matches('.bgg-more')) bad.push(`${label}: radius ${cs.borderTopLeftRadius}`);
          if (cs.fontSize !== '14px' || cs.fontWeight !== '600') bad.push(`${label}: font ${cs.fontSize}/${cs.fontWeight}`);
          if (el.disabled) bad.push(`${label}: disabled`);
          if (R === 'pri' || R === 'sec') { const box = el.closest('.sheet, .sbox, .banner, .ebar, main'); if (box) { const bs = getComputedStyle(box), br = box.getBoundingClientRect(); const edge = br.right - parseFloat(bs.paddingRight) - parseFloat(bs.borderRightWidth); if (r.right > edge + 0.5) bad.push(`${label}: outlined button spills ${Math.round(r.right - edge)}px past the content edge`); } }
          if ((R === 'pri' || R === 'sec') !== (bw === 1)) bad.push(`${label}: ${R} stroke ${bw}px`);
          const c = cr(rgb(cs.color), bgOf(el)); if (c < 4.5) bad.push(`${label}: label contrast ${c.toFixed(2)}`);
          /* each role must actually render its paint (catches specificity losses): Peligro red, Terciaria not the Principal color */
          const col = cs.color, danger = getComputedStyle(document.documentElement).getPropertyValue('--color-danger').trim();
          const probe = v => { const t = document.createElement('i'); t.style.color = v; document.body.appendChild(t); const c = getComputedStyle(t).color; t.remove(); return c; };
          const dark = document.documentElement.dataset.theme === 'dark';
          if (R === 'dan' && col !== probe(dark ? '#F2A3B8' : danger)) bad.push(`${label}: Peligro renders ${col}, not danger`);
          if (R === 'ter' && col !== probe(getComputedStyle(document.documentElement).getPropertyValue('--ter').trim())) bad.push(`${label}: Terciaria renders ${col}, not --ter`);
        }
        const rows = new Set(btns.filter(el => role(el) === 'pri').map(el => el.parentElement));
        for (const row of rows) {
          const inRow = [...row.children].filter(el => btns.includes(el));
          const pris = inRow.filter(el => role(el) === 'pri');
          if (pris.length > 1) bad.push(`row with ${pris.length} Principal: ${pris.map(x => x.textContent.trim()).join(', ')}`);
          if (inRow.length && role(inRow[inRow.length - 1]) !== 'pri') bad.push(`Principal not last: ${inRow.map(x => x.textContent.trim()).join(' | ')}`);
        }
        const fields = [...dev.querySelectorAll('.tin, .field input, .sfield input')].filter(el => vis(el) && !el.matches('.desc-in, .num, .title-in') && document.activeElement !== el);
        for (const f of fields) { const cs = getComputedStyle(f); if (f.classList.contains('invalid')) continue; const w = parseFloat(cs.borderTopWidth); const c = Math.min(cr(rgb(cs.borderTopColor), bgOf(f)), cr(rgb(cs.borderTopColor), bgOf(f.parentElement))); if (w !== 1 || c < 3) bad.push(`field ${f.id || f.placeholder}: stroke ${w}px ${c.toFixed(2)}:1`); }
        /* type: only the weights the app ships (Inter 400/600, Bebas 400), and only real Inter/Bebas faces */
        const wbad = [...new Set([...dev.querySelectorAll('*')].filter(el => vis(el) && !['400', '600'].includes(getComputedStyle(el).fontWeight)).map(el => `${el.tagName.toLowerCase()}.${[...el.classList].join('.')}=${getComputedStyle(el).fontWeight}`))];
        if (wbad.length) bad.push('weights outside 400/600: ' + wbad.slice(0, 6).join(', '));
        const fbad = [...new Set([...dev.querySelectorAll('*')].filter(el => vis(el) && [...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim()) && !/^(Inter|"Bebas Neue")/.test(getComputedStyle(el).fontFamily)).map(el => getComputedStyle(el).fontFamily.split(',')[0]))];
        if (fbad.length) bad.push('text in other font families: ' + fbad.join(', '));
        /* state pairs must still differ by weight after normalizing (600/700 pairs collapse to 600/600) */
        const tabs = [...dev.querySelectorAll('.tabs button .tab-lbl')].filter(vis);
        const on = tabs.filter(t => t.closest('button').classList.contains('on')), off = tabs.filter(t => !t.closest('button').classList.contains('on'));
        if (on.length && off.length && !(+getComputedStyle(on[0]).fontWeight > +getComputedStyle(off[0]).fontWeight)) bad.push(`active tab label weight ${getComputedStyle(on[0]).fontWeight} not above inactive ${getComputedStyle(off[0]).fontWeight}`);

        /* ============ 065 R10: THE ACTION MATRIX ============================================
           064 defined the PAINT of a role and said nothing about which SHAPE a role takes in which
           place, so every context invented one. The census of all 113 visible action controls across
           25 admin surfaces found the same role rendering two ways in five context×role pairs, and
           three of those were real bugs no existing check could see — because this file only ever
           looked at buttons, and only ever at their right edge.
           The rule: THE CONTEXT PICKS THE ANATOMY, THE ROLE PICKS THE PAINT. Four anatomies, no fifth:
             A1 outlined  44px, 16px padding, 1px stroke, inset 0 on BOTH sides, 8px between two
             A2 text      44px, 12px padding, no stroke, pulled -12px so the LABEL lands on the edge,
                          0 between two of them (round 6 #5), centred and unpulled in pagination only
             A3 icon      44x44 borderless, 18px glyph, pulled -12px so the GLYPH lands on the edge
             A4 sheet row 48px, full-bleed, 16px/400 - a sheet has no buttons at all (R7b)
           A1-A9 below are the enforcement. They are HERE and not in 065's verify.js on purpose:
           round 4 and round 9 both found a control that nothing audited, and a rule that lives only in
           the composition drifts the moment a sketch is edited on its own. */
        const abad = [];
        const ACT = '.obtn, .tbtn, .b-pri, .b-sec, .cta2, .ibtn';
        const acts = [...dev.querySelectorAll(ACT)].filter(el => !el.closest('.snack') && vis(el));
        const outlined = el => el.matches('.obtn, .b-pri, .b-sec');
        const borderless = el => !outlined(el);
        const lbl = el => (el.textContent.trim() || el.getAttribute('aria-label') || '·').slice(0, 22);
        /* the BLOCK an action belongs to: the nearest labelled surface, so a .grp inside a section is
           its own block (which is why "Ordenar" on the list and "Agregar juegos" on an open estante
           are one outline each and not two in one place). */
        const blockOf = el => el.closest('.sheet, .sbox, .banner, .ebar, .grp, .jsec, section, main');
        /* the STRIP an action sits in: the flex row that holds it, which is what carries the gap. */
        const stripOf = el => el.parentElement;
        const edges = (el, box) => { const bs = getComputedStyle(box), br = box.getBoundingClientRect(), r = el.getBoundingClientRect();
          return { l: r.left - (br.left + parseFloat(bs.paddingLeft) + parseFloat(bs.borderLeftWidth)),
                   r: (br.right - parseFloat(bs.paddingRight) - parseFloat(bs.borderRightWidth)) - r.right }; };
        /* A5 — contexts that may never hold an outlined action: a page-level strip (it sits under
           content it does not belong to), anything at row level, pagination, and a sheet. */
        const NO_OUTLINE = '.pacts, .gxacts, .epanel, .gtrail, .more, .ractions, .grow, .sheet';
        for (const el of acts) {
          const box = blockOf(el); if (!box) continue;
          const e = edges(el, box);
          /* A2 — an outlined action never pulls: its stroke ends on the content edge, both sides. */
          if (outlined(el) && (e.l < -0.5 || e.r < -0.5))
            abad.push(`A2 ${lbl(el)}: outlined action hangs ${Math.round(Math.min(e.l, e.r))}px past its block's content edge (A1 never pulls)`);
          /* A3 — a borderless action AT a block edge pulls, so its label or glyph lands on the edge and
             not its invisible box. Only judged when it is the outermost thing on that side, and never
             on a FULL-WIDTH bar (a box footer like "Ver más" or pagination): there the box IS the strip
             and the label is centred inside it, so there is no edge for a label to land on. */
          const bw2 = box.getBoundingClientRect().width - parseFloat(getComputedStyle(box).paddingLeft) - parseFloat(getComputedStyle(box).paddingRight);
          const fullWidth = el.getBoundingClientRect().width >= bw2 * 0.9;
          if (borderless(el) && !fullWidth && !el.closest('.more, .dlinks, .sfield')) {
            for (const [side, v] of [['left', e.l], ['right', e.r]])
              if (v > -14 && v < 14 && !(v <= -8 && v >= -14))
                abad.push(`A3 ${lbl(el)}: borderless action sits ${Math.round(v)}px from its block's ${side} content edge — its label, not its box, belongs there (-12)`);
          }
          /* A5 */
          if (outlined(el) && el.closest(NO_OUTLINE))
            abad.push(`A5 ${lbl(el)}: outlined action in a context that may not hold one (${[...el.classList].join('.')} inside ${el.closest(NO_OUTLINE).className.trim().split(/\s+/)[0]})`);
          /* A7 — a destructive action is never outlined and never Principal. */
          if (el.matches('.danger') && outlined(el))
            abad.push(`A7 ${lbl(el)}: a destructive action is outlined`);
        }
        /* A4 — a block holds at most ONE outlined action, unless the second is that block's Principal.
           Three equal Secundarias and no Principal is what "kills the balance": the page asks for
           nothing and shouts three times. */
        const byBlock = new Map();
        for (const el of acts.filter(outlined)) { const b = blockOf(el); if (!b) continue; if (!byBlock.has(b)) byBlock.set(b, []); byBlock.get(b).push(el); }
        for (const [b, list] of byBlock) {
          const pri = list.filter(el => el.matches('.obtn, .b-pri')), sec = list.filter(el => el.matches('.b-sec'));
          if (pri.length > 1 || sec.length > 1)
            abad.push(`A4 ${b.className.trim().split(/\s+/)[0] || b.tagName.toLowerCase()}: ${pri.length} Principal + ${sec.length} Secundaria outlined in one block (${list.map(lbl).join(' | ')}) — at most one of each, and never two Secundarias`);
        }
        /* A6 — the gap between two actions in one strip: 0 between borderless ones (their own 12px
           padding IS the rhythm, round 6 #5), 8px between outlined ones. Measured on the strip, which
           is where the four different answers the census found were declared. */
        const strips = new Set(acts.map(stripOf).filter(Boolean));
        for (const st of strips) {
          const kids = [...st.children].filter(el => acts.includes(el));
          if (kids.length < 2 || st.matches('.more, .dlinks')) continue;
          const g = getComputedStyle(st).columnGap, gp = g === 'normal' ? 0 : parseFloat(g);
          const anyOutlined = kids.some(outlined);
          const want = anyOutlined ? 8 : 0;
          if (gp !== want) abad.push(`A6 ${st.className.trim().split(/\s+/)[0] || st.tagName.toLowerCase()}: ${gp}px between ${anyOutlined ? 'outlined' : 'text'} actions (${kids.map(lbl).join(' | ')}) — want ${want}px`);
        }
        /* A8 — the 44px floor on anything you tap, a row that opens a sheet included. The chip is the
           reason this measures the HIT box and not the drawn box: 061's filter chip is a 32px pill whose
           ::after bleeds its target to 44, which is legal and which a naive height check would fail. */
        const tappables = [...dev.querySelectorAll(ACT + ', .dlink, button.srow, label.srow, a.srow, .chip, .grow, .grow .gmain')]
          .filter(el => !el.closest('.snack') && vis(el));
        for (const el of tappables) {
          const r = el.getBoundingClientRect(), a = getComputedStyle(el, '::after');
          const t = parseFloat(a.top), b2 = parseFloat(a.bottom);
          const hit = a.content !== 'none' && !isNaN(t) && !isNaN(b2) ? r.height - t - b2 : r.height;
          if (hit < 43.5) abad.push(`A8 ${lbl(el)} (${el.className.trim().split(/\s+/)[0]}): ${Math.round(hit)}px tap target, under the 44px floor`);
        }
        /* A9 — a sheet has no buttons: its actions are .dlink rows, the committing one first with a
           tick and Cancelar last with a chevron-left (R7b). */
        for (const sh of dev.querySelectorAll('.sheet.open')) {
          const btnsIn = [...sh.querySelectorAll('.obtn, .tbtn, .b-pri, .b-sec, .cta2')].filter(vis);
          if (btnsIn.length) abad.push(`A9 a sheet renders ${btnsIn.length} button(s) instead of rows (${btnsIn.map(lbl).join(' | ')})`);
          const rows = [...sh.querySelectorAll('.dlinks .dlink')].filter(vis);
          if (rows.length > 1) {
            const last = rows[rows.length - 1];
            if (/^Cancelar/.test(last.textContent.trim()) === false && rows.some(r => /^Cancelar/.test(r.textContent.trim())))
              abad.push(`A9 a sheet's Cancelar is not last (${rows.map(lbl).join(' | ')})`);
          }
        }
        return { n: btns.length, roles: btns.map(el => role(el) + ':' + (el.textContent.trim() || '·')), fields: fields.length, bad,
          acts: acts.length, tappables: tappables.length, abad, setupErr: window.__setupErr || null };
      });
      if (theme === 'light' && name === screens[0][0]) ok(await p.evaluate(() => [...document.fonts].filter(f => f.status === 'loaded').some(f => f.family.replace(/"/g, '') === 'Inter' && f.weight === '600') && document.fonts.check('600 14px Inter') && document.fonts.check('400 14px Inter')), `${sketch}: real self-hosted Inter 400/600 loaded`);
      ok(!a.setupErr, `${sketch} ${name} ${theme}: setup ran ${a.setupErr || ''}`);
      ok(a.bad.length === 0, `${sketch} ${name} ${theme}: ${a.n} buttons, ${a.fields} fields follow the system ${a.bad.join(' · ')}`);
      /* 065 R10: and the action matrix — which anatomy a role takes in which context (A1–A9 above) */
      ok(a.abad.length === 0, `${sketch} ${name} ${theme}: ${a.acts} actions, ${a.tappables} tap targets follow the R10 action matrix ${a.abad.join(' · ')}`);
      if (theme === 'light') log.push(`     roles: ${a.roles.join(' ')}`);
      await (await p.$('#device')).screenshot({ path: `${OUT}/${sketch}-${name}-${theme}.png` });
    }
    ok(errs.length === 0, `${sketch}: no JS errors ${errs.join(' | ')}`);
    await p.close();
  }
  console.log(log.join('\n')); const fails = log.filter(l => l.startsWith('FAIL')).length, passes = log.filter(l => l.startsWith('PASS')).length;
  console.log(`\n${passes}/${passes + fails} passed · screenshots in ${OUT}`); await b.close(); process.exitCode = fails ? 1 : 0;
})().catch(e => { console.log(log.join('\n')); console.error('CRASH', e.message); process.exit(1); });
