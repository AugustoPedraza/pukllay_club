/* Headless-Chrome checks for sketch 074 (the editor's header). Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/074-admin-header/verify.js
   Env: PLAYWRIGHT_CORE, SKETCH_URL, SHOTS_DIR (default <os tmp>/sketch-074-shots).

   ROUND 3. Round 1's H1 and H3 are gone along with their comparison checks — their question is answered
   and their measurements live in the README. What is on screen is the decision, not a menu of them.
   Round 3's own axis is the CTA's WEIGHT: W1 Relleno · W2 Contorno · W3 Texto, paint only (checks 18-22).

   `HOY` — the three-piece chrome 073 ships — stays, and every assertion claiming "W1 does not do X" is
   paired with one asserting HOY DOES. Across 073's four rounds the suite was green while the page was
   wrong FIVE times; in round 1 of this sketch it was green over TWO real defects at once (`.hdr` and
   `.tbar` both set `display` on a class, which out-specifies `[hidden]`, so neither ever hid — and check 1
   trusted the attribute rather than the screen, so the page and the check were wrong in the same direction
   and agreed with each other).

   Traps this file is written around, all of which have produced fake findings in this project:
     · CDP synthesizeScrollGesture yields Δ0 here — scroll is driven by setting `scroller.scrollTop`.
     · CDP touch does not set `:active` — nothing here asserts a press state.
     · Visibility is `offsetParent !== null`, NEVER `el.hidden` or the element's own computed display.
     · Touch floors are hit-tested with `elementFromPoint`, and the hit must BE the control or a descendant,
       so a parent cannot swallow the probe. Round 2's CTA is 36px tall with a 44px pseudo-element hit box,
       so check 8 probes ABOVE and BELOW the visible box and is negative-tested by removing it. */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();
const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/074-admin-header/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-074-shots'); fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);

/* ROUND 3 splits N1 into three CTA weights that differ in PAINT ONLY. The structural suite (checks 1-17)
   runs against W1 — round 2's N1 byte-for-byte apart from the paint — so it keeps one incumbent rather than
   tripling its wall time on three structurally identical pages; check 18b asserts that identity on the two
   situations that carry it, so W2 and W3 cannot drift structurally behind the suite's back. */
const ALL = ['W1', 'HOY'];
const WEIGHTS = ['W1', 'W2', 'W3'];
const WNAME = { W1: 'Relleno', W2: 'Contorno', W3: 'Texto' };

/* d42's eight situations. `dead` marks the ONE where nothing is pending — the only place round 2's slot is
   allowed to hold a disabled control. Encoded here so check 12 fails loudly if it ever becomes two. */
const SITS = [
  { k: 'pub·sin-id·limpio',    cy: 'published', st: 'no_bgg_id',   d: false, want: 'Vincular',    dead: false },
  { k: 'pub·sin-id·sucio',     cy: 'published', st: 'no_bgg_id',   d: true,  want: 'Guardar',     dead: false },
  { k: 'pub·con-datos·limpio', cy: 'published', st: 'enriched',    d: false, want: 'Guardar',     dead: true  },
  { k: 'pub·con-datos·sucio',  cy: 'published', st: 'enriched',    d: true,  want: 'Guardar',     dead: false },
  { k: 'bor·con-datos·limpio', cy: 'draft',     st: 'enriched',    d: false, want: 'Publicar',    dead: false },
  { k: 'bor·con-datos·sucio',  cy: 'draft',     st: 'enriched',    d: true,  want: 'Guardar',     dead: false },
  { k: 'pub·id-malo·limpio',   cy: 'published', st: 'bgg_missing', d: false, want: 'Corregir ID', dead: false },
  { k: 'bor·sin-id·limpio',    cy: 'draft',     st: 'no_bgg_id',   d: false, want: 'Vincular',    dead: false }
];

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
  const cool = async () => { await p.mouse.move(-60, -60); await p.waitForTimeout(120); };

  const set = async (v, s, cy = 'published', makeDirty = false) => {
    await J(([vv, ss, cc]) => {
      document.querySelector(`[data-var="${vv}"]`).click();
      document.querySelector(`[data-st="${ss}"]`).click();
      document.querySelector(`[data-cy="${cc}"]`).click();
      document.getElementById('scroller').scrollTop = 0;
    }, [v, s, cy]);
    await p.waitForTimeout(90);
    if (makeDirty) {
      /* through the real UI — decision 41 deleted the sheets' commit buttons, so picking the other value
         commits and closes in one tap */
      await J(() => document.querySelector('[data-edit="is_expansion"]').click());
      await p.waitForTimeout(140);
      await J(() => document.querySelector('[data-pick="is_expansion"][data-val="true"]').click());
      await p.waitForTimeout(180);
      await J(() => { document.getElementById('scroller').scrollTop = 0; });
    }
    await cool();
  };
  const toBottom = () => J(() => { const s = document.getElementById('scroller'); s.scrollTop = s.scrollHeight; return s.scrollTop; });
  const vis = `el => el && el.offsetParent !== null`;

  /* ================= 1. what the chrome costs, and what collapsing it gives back ================= */
  {
    const measure = () => J(() => {
      const v = el => el && el.offsetParent !== null;
      const h = document.getElementById('hdr'), t = document.getElementById('tbar'), back = document.querySelector('.back');
      const hdrH = v(h) ? h.getBoundingClientRect().height : 0;
      const tbarH = v(t) ? t.getBoundingClientRect().height : 0;
      const backH = v(back) ? back.getBoundingClientRect().height : 0;
      return { hdrH, tbarH, backH, total: hdrH + tbarH + backH };
    });
    await set('HOY', 'no_bgg_id'); const hoy = await measure();
    await set('W1', 'no_bgg_id');  const n1 = await measure();
    ok(hoy.hdrH === 53 && hoy.backH >= 44,
      `NEGATIVE TEST — HOY really does stack a ${hoy.hdrH}px wordmark header above a ${hoy.backH}px in-page back row (${hoy.total}px before the game's name)`);
    ok(n1.hdrH === 0 && n1.backH === 0 && n1.tbarH === 56,
      `W1: one 56px top bar replaces both (hdr ${n1.hdrH}, back row ${n1.backH})`);
    ok(n1.total < hoy.total, `W1: ${hoy.total - n1.total}px of chrome given back (${hoy.total} → ${n1.total})`);
  }

  /* ================= 2. the back affordance exists once ================= */
  {
    const backs = () => J(() => [...document.querySelectorAll('.back, .pb-back, .tb-back')].filter(el => el.offsetParent !== null).length);
    await set('HOY', 'no_bgg_id'); const h = await backs();
    ok(h === 2, `NEGATIVE TEST — HOY really does carry ${h} back controls for one destination (expected 2)`);
    await set('W1', 'no_bgg_id'); const n = await backs();
    ok(n === 1, `W1: exactly one back control (${n})`);
  }

  /* ================= 3. the W variants have no bottom bar, in any of the eight situations =================
     Round 1's H1 kept one and split the action area in 3 of 8; worse, `Descartar` was pushed into R359 —
     the exact edge `Guardar` held in the other five — so the editor taught "bottom-right is safe" and then
     put the undo-everything button there. W1 deletes the bar outright. */
  {
    for (const v of ALL) {
      const lit = [];
      for (const s of SITS) {
        await set(v, s.st, s.cy, s.d);
        lit.push(await J(() => {
          const slot = document.querySelector('.tb-act'), bar = document.getElementById('savebar');
          const a = slot && slot.offsetParent !== null && slot.querySelector('button') ? 1 : 0;
          const b = bar && bar.classList.contains('on') && bar.querySelector('button') ? 1 : 0;
          return a + b;
        }));
      }
      ok(Math.max(...lit) <= 1, `${v}: never more than one action container lit (worst ${Math.max(...lit)}/8)`);
    }
    let barSeen = 0;
    for (const s of SITS) {
      await set('W1', s.st, s.cy, s.d);
      barSeen += await J(() => document.getElementById('savebar').classList.contains('on') ? 1 : 0);
    }
    ok(barSeen === 0, `W1: the bottom bar never appears (${barSeen}/8)`);
    await set('HOY', 'enriched', 'published', true);
    const hoyBar = await J(() => document.getElementById('savebar').classList.contains('on'));
    ok(hoyBar, `NEGATIVE TEST — HOY really does show the bottom bar while dirty, so check 3 can fail`);
  }

  /* ================= 4. where the thing to tap is ================= */
  {
    const probe = () => J(() => {
      const b = [...document.querySelectorAll('.tb-act .btn, #savebar .btn')]
        .filter(x => !x.classList.contains('ghost'))
        .filter(x => { const r = x.getBoundingClientRect(); return r.width > 0 && r.height > 0; })[0];
      if (!b) return null;
      const r = b.getBoundingClientRect();
      return { label: b.textContent.trim(), dis: b.disabled, right: Math.round(r.right),
               cy: Math.round(r.top + r.height / 2), h: Math.round(r.height),
               dist: Math.round(Math.hypot(375 - (r.left + r.width / 2), 740 - (r.top + r.height / 2))) };
    });
    for (const v of ALL) {
      const hits = [];
      for (const s of SITS) { await set(v, s.st, s.cy, s.d); const r = await probe(); if (r) hits.push(r); }
      const edges = [...new Set(hits.map(h => h.right))], ys = [...new Set(hits.map(h => h.cy))];
      ok(edges.length === 1, `${v}: the primary's right edge — ${edges.length === 1 ? `fixed at R${edges[0]}` : `MOVES between ${edges.map(e => 'R' + e).join(' / ')}`}`);
      ok(ys.length === 1, `${v}: the primary sits at ${ys.length} vertical position${ys.length === 1 ? ` (${ys[0]}px)` : `s (${ys.join(', ')})`} · reach from bottom-right ${Math.min(...hits.map(h => h.dist))}–${Math.max(...hits.map(h => h.dist))}px`);
    }
  }

  /* ================= 12. the slot is dead in exactly ONE situation =================
     ROUND 2'S LOAD-BEARING CHECK. The developer asked for an enabled/disabled CTA in place of the words
     "Cambios sin guardar". Taken literally that is what d42 REJECTED — a fixed Guardar put a dead control
     in the strongest slot in 4 of 8 and demoted the real next step to a ghost. The amendment is that the
     slot SWAPS and falls back to a disabled Guardar only where `primary()` has nothing to offer.
     This check exists so that "1 of 8" cannot quietly drift back to 4. */
  {
    const slot = () => J(() => {
      const b = document.querySelector('.tb-act .btn');
      return b ? { label: b.textContent.trim(), dis: !!b.disabled } : null;
    });
    const dead = [];
    let labelled = 0;
    for (const s of SITS) {
      await set('W1', s.st, s.cy, s.d);
      const r = await slot();
      if (!r) { ok(false, `W1 · ${s.k}: the slot is EMPTY — it must always hold a control`); continue; }
      if (r.dis) dead.push(s.k);
      if (r.label === s.want) labelled++;
      ok(r.dis === s.dead, `W1 · ${s.k}: "${r.label}" ${r.dis ? 'disabled' : 'enabled'} (expected ${s.dead ? 'disabled' : 'enabled'})`);
    }
    ok(dead.length === 1 && dead[0] === 'pub·con-datos·limpio',
      `W1: the slot is dead in ${dead.length}/8 — ${dead.join(', ')} — and only where nothing is pending (d42 allowed 0; it rejected 4)`);
    ok(labelled === 8, `W1: every situation shows the verb d42 says is next (${labelled}/8)`);
  }

  /* ================= 13. the CTA does not move when the title arrives =================
     The title is opacity-0 at rest, NOT display:none, so it keeps its flex space and the CTA is pinned at
     every scroll offset. If it ever collapsed, the CTA would slide left at rest and jump right on scroll —
     d42's "the thing to tap is moving" defect, reintroduced through the fade.
     NEGATIVE-TESTED by collapsing the title on purpose. */
  {
    await set('W1', 'enriched');
    const at = () => J(() => { const b = document.querySelector('.tb-act .btn'); return Math.round(b.getBoundingClientRect().right); });
    const rest = await at();
    await toBottom(); await p.waitForTimeout(220);
    const scrolled = await at();
    ok(rest === scrolled, `W1: the CTA's right edge is R${rest} at rest and R${scrolled} scrolled — it does not move when the title arrives`);
    await J(() => { document.getElementById('scroller').scrollTop = 0; document.getElementById('tbt').style.display = 'none'; });
    await p.waitForTimeout(140);
    const collapsed = await at();
    ok(collapsed !== rest, `NEGATIVE TEST — collapsing the title really does shift the CTA (R${rest} → R${collapsed}), so check 13 can fail`);
    await J(() => { document.getElementById('tbt').style.display = ''; });
  }

  /* ================= 14. the title is absent at rest and present scrolled =================
     The developer: *"not sure that I need to say where you go back or where you are since you can see it."*
     True at rest — round 1 put the name on screen THREE times inside 600px. Not true scrolled, which is
     D-19n. Both halves measured on a page that really scrolls. */
  {
    const nameCount = () => J(() => {
      const want = 'Brass: Birmingham';
      return [...document.querySelectorAll('.tb-t, .pb-t, .gh-name, .fr-v')].filter(el => {
        if (el.offsetParent === null) return false;
        const cs = getComputedStyle(el);
        if (cs.visibility === 'hidden' || +cs.opacity === 0) return false;
        const pb = el.closest('.pbar'); if (pb && !pb.classList.contains('on')) return false;
        const r = el.getBoundingClientRect();
        if (r.bottom <= 0 || r.top >= 740) return false;
        return el.textContent.trim().startsWith(want);
      }).length;
    });
    await set('W1', 'enriched');
    const atRest = await nameCount();
    await p.screenshot({ path: path.join(OUT, '14-n1-reposo.png') });
    const y = await toBottom(); await p.waitForTimeout(240);
    ok(y > 200, `W1: the page really scrolls (${y}px) — without this the next check passes vacuously`);
    const atBottom = await nameCount();
    await p.screenshot({ path: path.join(OUT, '14-n1-scrolleado.png') });
    ok(atRest === 2, `W1 at rest: the game's name is on screen ${atRest}× (the 22px head + the Nombre row) — round 1 had 3, the bar's copy is gone`);
    ok(atBottom >= 1, `W1 scrolled to the bottom: the name is back, in the bar (${atBottom}× on screen) — D-19n satisfied by a bar that was already there`);
    /* the baseline does the same job with a second bar that appears */
    await set('HOY', 'enriched'); await toBottom(); await p.waitForTimeout(240);
    const hoyBottom = await J(() => document.getElementById('pbar').classList.contains('on'));
    ok(hoyBottom, `NEGATIVE TEST — HOY really does solve this by fading in a SECOND bar (.pbar), the one the developer called useless`);
  }

  /* ================= 15. D-19f's dialog, drawn here for the first time in this project =================
     Anatomy is the rule's, not invented: 312px, 16px radius, 18/600 question, 14px muted consequence, two
     RIGHT-ALIGNED TEXT actions — Cancelar focused by default, the destructive verb in Peligro red — and
     scrim tap / Esc cancel. Checked against the rule's numbers rather than against how it looks. */
  {
    await set('W1', 'enriched', 'published', true);
    /* a clean editor must NOT confront you with a dialog — otherwise it is noise on 385 healthy games */
    await set('W1', 'enriched');
    await J(() => document.getElementById('tbback').click());
    await p.waitForTimeout(220);
    const cleanOpened = await J(() => document.getElementById('dlg').classList.contains('open'));
    ok(!cleanOpened, `W1: leaving a CLEAN editor does not confirm — no dialog on the 385 healthy games`);

    await set('W1', 'enriched', 'published', true);
    await J(() => document.getElementById('tbback').click());
    await p.waitForTimeout(260);
    const dlg = await J(() => {
      const d = document.getElementById('dlg');
      if (!d.classList.contains('open')) return null;
      const cs = getComputedStyle(d);
      const q = d.querySelector('h2'), c = d.querySelector('p');
      const acts = [...d.querySelectorAll('.acts button')];
      const qs = getComputedStyle(q), ds = getComputedStyle(acts[acts.length - 1]);
      return {
        w: Math.round(d.getBoundingClientRect().width), radius: cs.borderRadius,
        q: q.textContent.trim(), qSize: qs.fontSize, qWeight: qs.fontWeight,
        c: c.textContent.trim(), cSize: getComputedStyle(c).fontSize,
        acts: acts.map(b => ({ t: b.textContent.trim(), h: Math.round(b.getBoundingClientRect().height),
                               filled: getComputedStyle(b).backgroundColor !== 'rgba(0, 0, 0, 0)' })),
        dangerColor: ds.color,
        actsH: Math.round(d.querySelector('.acts').getBoundingClientRect().height),
        actsOneLine: Math.round(d.querySelector('.acts').getBoundingClientRect().height) <= 48,
        focused: document.activeElement ? document.activeElement.textContent.trim() : ''
      };
    });
    ok(!!dlg, `W1: leaving a DIRTY editor opens the confirmation`);
    ok(dlg && dlg.w === 312, `D-19f: the dialog is ${dlg && dlg.w}px wide (rule says 312)`);
    ok(dlg && dlg.radius === '16px', `D-19f: 16px radius (${dlg && dlg.radius})`);
    ok(dlg && dlg.qSize === '18px' && dlg.qWeight === '600', `D-19f: the question is 18/${dlg && dlg.qWeight} — "${dlg && dlg.q}"`);
    ok(dlg && dlg.cSize === '14px', `D-19f: one 14px consequence line — "${dlg && dlg.c}"`);
    ok(dlg && dlg.acts.length === 2 && dlg.acts.every(a => !a.filled),
      `D-19f: two TEXT actions, neither filled (${dlg && dlg.acts.map(a => a.t).join(' · ')})`);
    ok(dlg && dlg.acts.every(a => a.h >= 44), `D-19f: both actions clear the 44px floor (${dlg && dlg.acts.map(a => a.h + 'px').join(', ')})`);
    ok(dlg && /cancelar/i.test(dlg.focused), `D-19f: the SAFE action is focused by default ("${dlg && dlg.focused}")`);
    /* the action row is ONE line. The first build invented "Seguir editando" for the cancel, and at 312px
       BOTH actions wrapped to two lines — two text actions became a two-line block, and the focused one
       read as an outlined button. Caught in a screenshot, not by any number here, so it is now a number. */
    ok(dlg && dlg.actsOneLine, `D-19f: both actions fit on one line (row ${dlg && dlg.actsH}px, a single 44px action)`);

    /* Esc cancels, and it must reach the dialog before the sheet underneath it */
    await p.keyboard.press('Escape'); await p.waitForTimeout(200);
    const escClosed = await J(() => !document.getElementById('dlg').classList.contains('open'));
    ok(escClosed, `D-19f: Esc cancels the dialog`);
    const stillDirty = await J(() => !!document.querySelector('.tb-act .btn:not([disabled])'));
    ok(stillDirty, `D-19f: cancelling keeps the unsaved changes (the CTA is still live)`);

    /* the destructive verb really discards */
    await J(() => document.getElementById('tbback').click()); await p.waitForTimeout(240);
    await J(() => document.getElementById('dlg-leave').click()); await p.waitForTimeout(260);
    const afterLeave = await J(() => {
      const b = document.querySelector('.tb-act .btn');
      return { dis: !!b.disabled, label: b.textContent.trim() };
    });
    ok(afterLeave.dis, `D-19f: "Salir sin guardar" really discards — the slot falls back to a disabled "${afterLeave.label}"`);
    await p.screenshot({ path: path.join(OUT, '15-d19f-dialogo.png') });
  }

  /* ================= 16. Descartar is gone from the chrome, not relocated =================
     Round 1's finding was that `Descartar` inherited the primary's right edge. The fix is not to move it —
     it is to delete it. Its only remaining home is inside the dialog, where it is a red text action. */
  {
    let seen = 0;
    for (const s of SITS) {
      await set('W1', s.st, s.cy, s.d);
      seen += await J(() => [...document.querySelectorAll('#tbar button, #savebar button')]
        .filter(b => b.offsetParent !== null && /descartar/i.test(b.textContent)).length);
    }
    ok(seen === 0, `W1: "Descartar" appears ${seen} times in the permanent chrome — it lives only in the dialog`);
    await set('HOY', 'enriched', 'published', true);
    const hoySeen = await J(() => [...document.querySelectorAll('#savebar button')]
      .filter(b => b.offsetParent !== null && /descartar/i.test(b.textContent)).length);
    ok(hoySeen === 1, `NEGATIVE TEST — HOY really does carry a permanent Descartar while dirty (${hoySeen}), so check 16 can fail`);
  }

  /* ================= 8. the 36px CTA still has a 44px touch target =================
     The control was reduced from 44px to 36 because the developer said it looked huge at 79% of the bar's
     height. The floor is kept with a pseudo-element, the technique already used for the switch track — so
     the check must probe OUTSIDE the visible box. `getBoundingClientRect` alone is blind to this, which is
     exactly how a 44px check has passed over a real defect here before. Negative-tested. */
  {
    const floor = () => J(() => {
      const out = [];
      for (const b of document.querySelectorAll('.tb-back, .tb-act .btn')) {
        const r = b.getBoundingClientRect();
        if (r.width === 0) continue;
        const mid = r.left + r.width / 2;
        /* Probe 3px above and below the VISIBLE box: outside the 36px button, inside the 44px hit box.
           NOT 4px — the box extends exactly (44-36)/2 = 4px past each edge, so a probe at 4 lands on the
           boundary and misses below while hitting above, which read as a half-broken hit box rather than
           as an off-by-one in the probe. The margin has to be strictly inside the extension it is testing. */
        const above = document.elementFromPoint(mid, r.top - 3);
        const below = document.elementFromPoint(mid, r.bottom + 3);
        const hitAbove = above && (above === b || b.contains(above));
        const hitBelow = below && (below === b || b.contains(below));
        out.push({ n: b.id || b.textContent.trim() || 'back', h: Math.round(r.height), hitAbove, hitBelow });
      }
      return out;
    });
    await set('W1', 'no_bgg_id');
    const c = await floor();
    const cta = c.find(x => /vincular/i.test(x.n));
    ok(cta && cta.h === 36, `W1: the CTA is ${cta && cta.h}px tall — 64% of the 56px bar, against round 1's 44px (79%)`);
    ok(cta && cta.hitAbove && cta.hitBelow,
      `W1: the CTA's hit box reaches 4px above AND below the visible button — the 44px floor is real, not drawn`);
    /* negative test: kill the pseudo-element and confirm the probe goes red */
    await J(() => {
      const st = document.createElement('style'); st.id = 'kill';
      st.textContent = '.tbar .btn::before { display: none !important; }';
      document.head.appendChild(st);
    });
    await p.waitForTimeout(120);
    const broke = await floor();
    const cta2 = broke.find(x => /vincular/i.test(x.n));
    ok(cta2 && !cta2.hitAbove && !cta2.hitBelow,
      `NEGATIVE TEST — removing the pseudo-element really does drop the hit box to the visible 36px, so check 8 can fail`);
    await J(() => document.getElementById('kill')?.remove());
  }

  /* ================= 9. exactly one Guardar in the editor (decision 41, one floor up) ================= */
  {
    for (const v of ALL) {
      for (const s of SITS.filter(x => x.d)) {
        await set(v, s.st, s.cy, true);
        const n = await J(() => [...document.querySelectorAll('button')]
          .filter(b => b.offsetParent !== null && /^guardar$/i.test(b.textContent.trim())).length);
        ok(n === 1, `${v} · ${s.k}: exactly one visible "Guardar" (${n})`);
      }
    }
  }

  /* ================= 10. typing reaches the slot, with the keyboard up ================= */
  {
    await set('W1', 'enriched');
    await J(() => document.querySelector('[data-edit="name"]').click());
    await p.waitForTimeout(220);
    await p.click('#s-name');
    await p.keyboard.type(' II');
    await p.waitForTimeout(220);
    const step = await J(() => {
      const b = document.querySelector('.tb-act .btn');
      return { label: b.textContent.trim(), dis: !!b.disabled, title: document.getElementById('tbt').textContent };
    });
    ok(step.label === 'Guardar' && !step.dis, `W1: typing flips the slot to an enabled "${step.label}" — the CTA IS the unsaved-changes signal`);
    ok(/ II$/.test(step.title), `W1: the bar's title tracks the name being typed ("${step.title}")`);
    await p.screenshot({ path: path.join(OUT, '10-n1-teclado.png') });
    await J(() => document.querySelector('[data-close]')?.click());
    await p.waitForTimeout(160);
  }

  /* ================= 7. nothing covers the last row at full scroll ================= */
  {
    for (const v of ALL) {
      await set(v, 'enriched', 'published', true);
      await toBottom(); await p.waitForTimeout(200);
      const o = await J(() => {
        const bar = document.getElementById('savebar');
        if (!bar || !bar.classList.contains('on')) return 0;
        const rows = [...document.querySelectorAll('.frow, .kv')];
        if (!rows.length) return 0;
        return Math.max(0, Math.round(rows[rows.length - 1].getBoundingClientRect().bottom - bar.getBoundingClientRect().top));
      });
      ok(o === 0, `${v}: nothing covers the last row at full scroll (${o}px)`);
    }
    await set('HOY', 'enriched', 'published', true);
    await J(() => { document.getElementById('device').classList.remove('hasbar'); });
    await toBottom(); await p.waitForTimeout(200);
    const broke = await J(() => {
      const bar = document.getElementById('savebar');
      const rows = [...document.querySelectorAll('.frow, .kv')];
      return Math.max(0, Math.round(rows[rows.length - 1].getBoundingClientRect().bottom - bar.getBoundingClientRect().top));
    });
    ok(broke > 0, `NEGATIVE TEST — removing HOY's bar reserve really does bury the last row by ${broke}px, so check 7 can fail`);
    await J(() => document.getElementById('device').classList.add('hasbar'));
  }

  /* ================= ROUND 3: the CTA's weight =================
     One shared probe. Everything below is computed from what the browser actually resolved — never from
     what the CSS was meant to say — and every colour is COMPOSITED by hand, because `opacity: .42` on the
     control means `getComputedStyle().color` reports the paint BEFORE the group is faded. A check that read
     the raw token would report a disabled text button at 14:1 and be wrong by the whole width of the
     question.

     TWO METRICS WERE THROWN AWAY BEFORE THIS ONE STOOD UP, and both failed in the same way — well-defined
     for two weights and meaningless for the third:

       · "the label against the bar" is nonsense for W1. Its label is white, the bar is white, and the fill
         sits between them so they never touch; the probe dutifully returned 1:1, a true number about a
         comparison that does not exist on screen.
       · "three different box readings" assumed the three weights use three inks. They do not. In light
         `--color-primary` and `--color-accent-text` are THE SAME HEX (#3C1269), so a fill and a stroke are
         the same ink at the same 14.16:1 and contrast cannot tell them apart — what differs is HOW MUCH of
         it is painted.

     So the axis is AREA, and contrast is the second question (it decides legibility, not weight). `dom` is
     the dominant ink — fill, else stroke, else label — against the bar, one quantity that means the same
     thing for all three. `paint` is the container's painted area in px². Both are exact rather than
     sampled: there are no gradients or images in this bar, so the geometry and the tokens give the answer
     outright. */
  const inkProbe = () => J(() => {
    const parse = c => (String(c).match(/[\d.]+/g) || []).map(Number);
    const over = (fg, bg, a) => [0, 1, 2].map(i => a * fg[i] + (1 - a) * bg[i]);
    const lum = c => { const f = v => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
                       return 0.2126 * f(c[0]) + 0.7152 * f(c[1]) + 0.0722 * f(c[2]); };
    const cr = (a, b) => { const x = lum(a), y = lum(b); const [h, l] = x > y ? [x, y] : [y, x];
                           return Math.round(((h + 0.05) / (l + 0.05)) * 100) / 100; };

    const bar = document.querySelector('.tbar');
    const btn = document.querySelector('.tb-act .btn');
    const title = document.getElementById('tbt');
    if (!bar || !btn || bar.offsetParent === null) return null;
    const barBg = parse(getComputedStyle(bar).backgroundColor).slice(0, 3);
    const cs = getComputedStyle(btn);
    const a = +cs.opacity;

    const fillRaw = parse(cs.backgroundColor);
    const fillA = fillRaw.length === 4 ? fillRaw[3] : 1;
    const hasFill = fillA > 0.01;
    const sh = cs.boxShadow && cs.boxShadow !== 'none' ? cs.boxShadow : null;
    const hasStroke = !!sh && /inset/.test(sh);
    const strokeRGB = hasStroke ? parse(sh).slice(0, 3) : null;

    /* what sits immediately behind the label, then the whole group faded over the bar */
    const behind = hasFill ? over(fillRaw.slice(0, 3), barBg, fillA) : barBg;
    const labelFinal = over(parse(cs.color).slice(0, 3), behind, a);
    const behindFinal = over(behind, barBg, a);
    const strokeFinal = hasStroke ? over(strokeRGB, barBg, a) : null;

    const r = btn.getBoundingClientRect();
    /* the LABEL's own ink edge, which is what the eye reads as "where the action ends" — for a boxless
       weight it is the only edge there is */
    const span = btn.querySelector('span');
    const inkR = Math.round((hasFill || hasStroke) ? r.right : (span ? span.getBoundingClientRect().right : r.right - parseFloat(cs.paddingRight)));
    const tr = title ? title.getBoundingClientRect() : null;

    /* the container's PAINTED AREA — the axis the three weights actually differ on. A fill covers the whole
       box; a 1px stroke covers only its perimeter; a text button covers nothing. Exact, not sampled. */
    const w = r.width, hh = r.height;
    const paint = hasFill ? Math.round(w * hh)
      : hasStroke ? Math.round(w * hh - Math.max(0, w - 2) * Math.max(0, hh - 2))
      : 0;

    return {
      a, hasFill, hasStroke, paint,
      /* does a CONTAINER read against the bar at all */
      box: hasFill ? cr(behindFinal, barBg) : hasStroke ? cr(strokeFinal, barBg) : 0,
      /* can the word still be READ off whatever is behind it */
      label: cr(labelFinal, behindFinal),
      /* the DOMINANT ink — fill, else stroke, else label — against the bar. One quantity that means the
         same thing for all three weights, unlike "the label against the bar" (see the note above). */
      dom: hasFill ? cr(behindFinal, barBg) : hasStroke ? cr(strokeFinal, barBg) : cr(labelFinal, barBg),
      h: Math.round(r.height), boxR: Math.round(r.right), inkR,
      /* what separates a truncated title from the action, in px of bare whitespace */
      gap: tr ? Math.round(r.left - tr.right) : null
    };
  });

  /* ================= 18. the three weights really are three weights =================
     THE GUARD THAT MAKES 19-21 MEAN ANYTHING. If the variant switch silently failed, or a weight class
     were left behind on the device, every comparison below would compare W1 to W1 and pass — the exact
     unfalsifiable shape that has produced fake findings in this project before. So the axis itself is
     asserted first, by what the browser resolved. */
  {
    const seen = {};
    for (const w of WEIGHTS) { await set(w, 'no_bgg_id'); seen[w] = await inkProbe(); }
    ok(seen.W1 && seen.W1.hasFill && !seen.W1.hasStroke, `W1 Relleno: a fill and no stroke (fill ${seen.W1 && seen.W1.hasFill}, stroke ${seen.W1 && seen.W1.hasStroke})`);
    ok(seen.W2 && !seen.W2.hasFill && seen.W2.hasStroke, `W2 Contorno: a stroke and no fill (fill ${seen.W2 && seen.W2.hasFill}, stroke ${seen.W2 && seen.W2.hasStroke})`);
    ok(seen.W3 && !seen.W3.hasFill && !seen.W3.hasStroke, `W3 Texto: neither (fill ${seen.W3 && seen.W3.hasFill}, stroke ${seen.W3 && seen.W3.hasStroke})`);
    /* The discriminator is PAINTED AREA, not colour — in light the fill token and the stroke token are the
       same hex, so a contrast-based guard here would compare 14.16 to 14.16 and pass vacuously. It was
       written that way first and failed; the note on the probe records why. */
    ok(new Set(WEIGHTS.map(w => seen[w].paint)).size === 3,
      `the three weights paint three different amounts of ink (${WEIGHTS.map(w => `${w} ${seen[w].paint}px²`).join(' · ')}) — same token, ${seen.W1.paint}× the coverage`);
    ok(seen.W1.dom === seen.W2.dom && seen.W2.dom === seen.W3.dom,
      `…and they all use the SAME ink at the SAME ${seen.W1.dom}:1 — in light \`--color-primary\` and \`--color-accent-text\` are one hex, so weight here is area and nothing else`);

    /* 18b — W2 and W3 are W1 STRUCTURALLY. The suite's 8-situation loops run against W1 only; this is what
       stops the other two drifting behind them. The two situations that carry the structure: the one where
       the slot is dead, and a broken game where it must hold the remedy. */
    for (const w of ['W2', 'W3']) {
      const rows = [];
      for (const k of ['pub·con-datos·limpio', 'pub·sin-id·limpio']) {
        const s = SITS.find(x => x.k === k);
        await set(w, s.st, s.cy, s.d);
        rows.push(await J(() => {
          const b = document.querySelector('.tb-act .btn');
          return { label: b ? b.textContent.trim() : null, dis: b ? !!b.disabled : null,
                   bar: document.getElementById('savebar').classList.contains('on'),
                   backs: [...document.querySelectorAll('.back, .pb-back, .tb-back')].filter(el => el.offsetParent !== null).length };
        }));
      }
      const good = rows[0].label === 'Guardar' && rows[0].dis === true
        && rows[1].label === 'Vincular' && rows[1].dis === false
        && rows.every(r => !r.bar && r.backs === 1);
      ok(good, `${w} is structurally W1 — same swapping slot ("${rows[0].label}" dead / "${rows[1].label}" live), no bottom bar, one back control`);
    }
  }

  /* ================= 19. paint is the ONLY axis — and where a boxless CTA ends =================
     Round 1 held the CTA byte-identical across positions so a finding about position could not be blamed on
     weight. This is that discipline inverted: geometry is pinned so a finding about weight cannot be blamed
     on size. The stroke is an inset box-shadow rather than a border for exactly this reason.

     It also records the cost d42's rule never anticipated. "The primary always ends at the same edge" was
     written for a control whose box IS its ink; W3 has no box, so the box edge and the ink edge come apart
     and only one of them can sit on the 16px keyline. W3 is drawn with the LABEL on the keyline, which puts
     its 44px hit target at R373 — two pixels from the bezel. Both numbers are reported rather than one. */
  {
    const g = {};
    for (const w of WEIGHTS) { await set(w, 'no_bgg_id'); g[w] = await inkProbe(); }
    ok(new Set(WEIGHTS.map(w => g[w].h)).size === 1,
      `the three weights are the same height (${WEIGHTS.map(w => g[w].h + 'px').join(' / ')}) — paint is the only axis`);
    ok(new Set(WEIGHTS.map(w => g[w].inkR)).size === 1,
      `every weight's INK ends on the same keyline (${WEIGHTS.map(w => `${w} R${g[w].inkR}`).join(' · ')}) — d42 holds for what the eye reads`);
    ok(g.W3.boxR > g.W1.boxR,
      `W3's cost, stated: with the label on the keyline its BOX — and the 44px hit target with it — overhangs to R${g.W3.boxR}, ${g.W3.boxR - g.W1.boxR}px past every other right edge and ${375 - g.W3.boxR}px from the bezel (W1/W2 end at R${g.W1.boxR})`);
  }

  /* ================= 20. what each weight costs the bar at full scroll =================
     The title is absent at rest, so at rest the bar is a chevron and an action and the weights are easy to
     tell apart. Scrolled is the hard case: a truncated title ends in an ellipsis and the action begins
     4px later. W1 and W2 put a box edge in that gap; W3 puts nothing there but whitespace, so a truncated
     title and the primary action run together into one line of text. Measured on the longest real name in
     the fixtures rather than asserted. */
  {
    /* THE FIRST VERSION OF THIS CHECK PASSED VACUOUSLY, and only the screenshot said so. It used
       `bgg_missing` because that fixture carries the long real name — but a broken game has no BGG facts,
       so the page is barely one screen tall, `toBottom()` moves nothing, and the title never fades in. The
       probe still returned a 4px gap, because `getBoundingClientRect()` is perfectly happy to measure an
       element at `opacity: 0`. Three weights, three identical numbers, all of them about an invisible
       element. The fixtures force the choice: the long name is on a page that does not scroll, and the page
       that scrolls has a short name — so the name is typed in through the real sheet, and the title's
       visibility and truncation are now ASSERTED before the gap is read. */
    const longName = 'Castillos del Rey Loco Ludwig';
    const r = {};
    for (const w of WEIGHTS) {
      await set(w, 'enriched');              // the only fixture with enough content to really scroll
      await J(() => document.querySelector('[data-edit="name"]').click());
      await p.waitForTimeout(220);
      await p.click('#s-name');
      await p.keyboard.press('Control+A');
      await p.keyboard.type(longName);
      await p.waitForTimeout(200);
      await J(() => document.querySelector('[data-close]')?.click());
      await p.waitForTimeout(200);
      const y = await toBottom(); await p.waitForTimeout(260);
      const live = await J(() => {
        const t = document.getElementById('tbt');
        return { scrolled: document.getElementById('scroller').scrollTop,
                 visible: +getComputedStyle(t).opacity === 1,
                 truncated: t.scrollWidth > t.clientWidth + 1 };
      });
      ok(live.scrolled > 200 && live.visible,
        `${w}: measured on a page that really scrolls (${live.scrolled}px) with the title really faded IN (opacity 1) — the first version of this check measured an invisible title on a page that never moved`);
      ok(live.truncated, `${w}: the title is really truncated at 375px, so there is an ellipsis beside the action`);
      r[w] = await inkProbe();
      await p.screenshot({ path: path.join(OUT, `20-${w}-titulo-y-cta.png`) });
    }
    ok(r.W1.gap === r.W2.gap && r.W2.gap === r.W3.gap,
      `the title-to-action gap is the same ${r.W1.gap}px in every weight — so what separates them is the PAINT, not the spacing`);
    ok(r.W1.box > 1.2 && r.W2.box > 1.2,
      `W1 and W2 put a container edge in that ${r.W1.gap}px (box ${r.W1.box}:1 and ${r.W2.box}:1 against the bar)`);
    ok(r.W3.box === 0,
      `W3 puts NOTHING there — ${r.W3.gap}px of whitespace between a truncated title and the primary, both of them bare text (box ${r.W3.box})`);
  }

  /* ================= 21. THE ROUND'S LOAD-BEARING CHECK: the disabled drop =================
     Round 2 left one sentence behind: *"a disabled filled button reads as lavender-and-live rather than
     clearly dead — a text button would disable unambiguously."* That is an adjective, and this is the
     number under it.

     The slot is dead in exactly one of d42's eight situations (`pub·con-datos·limpio`, check 12), and the
     weight that serves the editor best is the one that is loudest when there IS something to do and
     quietest when there is not. Both halves are measured, in BOTH themes, because the last two palette
     defects in this project were dark-only — and dark is where this is sharpest: `--color-accent-text`
     resolves to a near-white #E3D9F9 there, so the two boxless weights are painted in a very different
     ink from the light theme's #3C1269. */
  {
    const live = SITS.find(x => x.k === 'pub·sin-id·limpio');    // an enabled CTA: Vincular
    const dead = SITS.find(x => x.k === 'pub·con-datos·limpio'); // the one dead slot
    const theme = async t => { await J(tt => { document.querySelector(`[data-theme-set="${tt}"]`).click(); }, t); await p.waitForTimeout(90); };
    const table = {};
    for (const th of ['light', 'dark']) {
      await theme(th);
      for (const w of WEIGHTS) {
        await set(w, live.st, live.cy, live.d); const on = await inkProbe();
        await set(w, dead.st, dead.cy, dead.d); const off = await inkProbe();
        await p.screenshot({ path: path.join(OUT, `21-${th}-${w}-apagado.png`) });
        table[`${th}·${w}`] = { on, off };
      }
    }
    await theme('light');

    for (const th of ['light', 'dark']) {
      for (const w of WEIGHTS) {
        const { on, off } = table[`${th}·${w}`];
        ok(off.a < 1 && on.a === 1, `${th} ${w}: the dead slot really is faded (opacity ${off.a} vs ${on.a}) — without this the drop below is vacuous`);
      }
      ok(true, `${th} — dominant ink vs the bar, enabled → disabled:  ${WEIGHTS.map(w => {
        const { on, off } = table[`${th}·${w}`]; return `${w} ${WNAME[w]} ${on.dom}:1 → ${off.dom}:1`;
      }).join('  ·  ')}`);
      /* area is reported for the DEAD slot only. `opacity` does not change area, so an enabled→disabled
         pair would differ purely because "Vincular" and "Guardar" are different lengths — a number that
         looks like a finding and is really just the label. */
      ok(true, `${th} — painted container area in the dead slot:  ${WEIGHTS.map(w =>
        `${w} ${table[`${th}·${w}`].off.paint}px²`).join('  ·  ')}`);
    }

    /* A DARK-ONLY ASYMMETRY IN THE INCUMBENT. Dark `--color-primary` (#7B2DCE) against the bar's #2E154E is
       2.33:1, where the same weight is 14.16:1 in light — the fill all but merges with the bar.

       STATED AS MEASURED, NOT AS A VERDICT. This is NOT asserted to be a WCAG 1.4.11 failure: 1.4.11 covers
       visual information REQUIRED to identify a control, and the screenshot shows W1's white 15.75:1 label
       identifying it perfectly well without help from the boundary. What the number does establish is that
       W1's weight is not portable across the two themes — it buys its prominence from the fill in light and
       from the LABEL in dark, so "filled is the loudest" is a light-theme fact, not a property of the
       weight. W2 carries the same 11.67:1 stroke in both. */
    ok(table['dark·W1'].on.box < 3 && table['light·W1'].on.box > 10,
      `dark W1: the fill reads ${table['dark·W1'].on.box}:1 against the bar vs ${table['light·W1'].on.box}:1 in light — the container nearly vanishes, and only the white label still identifies it (flag, not a 1.4.11 verdict: the label does that job)`);
    ok(table['dark·W2'].on.box >= 3,
      `dark W2: the stroke reads ${table['dark·W2'].on.box}:1 — the one weight whose container survives both themes, because dark \`--color-accent-text\` is a near-white #E3D9F9`);

    /* the finding itself, as an assertion rather than a report: a dead W1 still paints a container against
       the bar, and a dead W3 paints nothing at all. If that ever stops being true the round's conclusion
       has to be revisited, and this is what will say so. */
    for (const th of ['light', 'dark']) {
      ok(table[`${th}·W1`].off.paint > 0,
        `${th} W1: DISABLED, it still paints a ${table[`${th}·W1`].off.paint}px² container at ${table[`${th}·W1`].off.box}:1 — a dead control that keeps the whole silhouette of a live one`);
      ok(table[`${th}·W3`].off.paint === 0,
        `${th} W3: DISABLED, nothing is painted at all — just a word that fades ${table[`${th}·W3`].on.dom}:1 → ${table[`${th}·W3`].off.dom}:1`);
    }
  }

  /* ================= 22. does the action still outrank the back control? =================
     The cost of going lighter that nobody asks about. The bar holds two controls: a bare chevron in
     `--color-text` on the left and the action on the right. At W1 the action is the only filled thing in
     the bar and the ranking is obvious. At W3 both are bare ink in a palette where they are nearly the same
     value — so the question is whether anything at all still says which of the two is the thing to do.
     Reported as area beside contrast, because contrast alone answers it wrongly (see the probe's note). */
  {
    const pair = () => J(() => {
      const parse = c => (String(c).match(/[\d.]+/g) || []).map(Number);
      const lum = c => { const f = v => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
                         return 0.2126 * f(c[0]) + 0.7152 * f(c[1]) + 0.0722 * f(c[2]); };
      const cr = (a, b) => { const x = lum(a), y = lum(b); const [h, l] = x > y ? [x, y] : [y, x];
                             return Math.round(((h + 0.05) / (l + 0.05)) * 100) / 100; };
      const bar = document.querySelector('.tbar');
      const barBg = parse(getComputedStyle(bar).backgroundColor).slice(0, 3);
      const back = document.querySelector('.tb-back');
      return { back: cr(parse(getComputedStyle(back).color).slice(0, 3), barBg) };
    });
    const rank = {};
    for (const w of WEIGHTS) {
      await set(w, 'no_bgg_id');
      const q = await pair();
      const probe = await inkProbe();
      rank[w] = { ...probe, back: q.back };
      ok(true, `${w} ${WNAME[w]}: the live action is ${probe.dom}:1 over ${probe.paint}px² against a ${q.back}:1 back chevron`);
    }
    /* the assertion, not the report. W1 and W2 outrank the chevron by painting a container it does not
       have; W3 has no container, so all that separates the primary action from a navigation glyph is that
       one is a word — and in light they are within 3:1 of the same ink. */
    ok(rank.W1.paint > 0 && rank.W2.paint > 0 && rank.W3.paint === 0,
      `W1 and W2 outrank the back chevron with a container it does not have (${rank.W1.paint}px² / ${rank.W2.paint}px² vs 0); W3 has none, so only "it is a word, not a glyph" separates the primary from navigation`);
  }

  /* ================= 17. screenshots — LOOK AT THEM =================
     The house rule that has caught what the numbers could not, every round. `published · no_bgg_id · clean`
     IS the 49 real games, the row that decided d42. Both themes, because the last two palette defects in
     this project were dark-only. */
  {
    const theme = async t => { await J(tt => { document.querySelector(`[data-theme-set="${tt}"]`).click(); }, t); await p.waitForTimeout(90); };
    for (const th of ['light', 'dark']) {
      await theme(th);
      /* every weight on the row that decided d42 (the 49 real broken games), plus the baseline */
      for (const v of [...WEIGHTS, 'HOY']) {
        await set(v, 'no_bgg_id'); await p.screenshot({ path: path.join(OUT, `17-${th}-${v}-los-49.png`) });
        await set(v, 'enriched', 'published', true); await p.screenshot({ path: path.join(OUT, `17-${th}-${v}-sucio.png`) });
      }
      /* the one dead situation, in all three weights — this is the comparison round 3 exists to make */
      for (const w of WEIGHTS) { await set(w, 'enriched'); await p.screenshot({ path: path.join(OUT, `17-${th}-${w}-nada-pendiente.png`) }); }
    }
    await theme('light');
    ok(true, `screenshots in ${OUT}`);
  }

  ok(errs.length === 0, `no page errors (${errs.length}${errs.length ? ': ' + errs.join(' | ') : ''})`);

  await browser.close();
  const pass = log.filter(l => l.startsWith('PASS')).length;
  console.log(log.join('\n'));
  console.log(`\n${pass}/${log.length}`);
  process.exit(pass === log.length ? 0 : 1);
})();
