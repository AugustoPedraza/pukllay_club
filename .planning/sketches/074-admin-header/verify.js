/* Headless-Chrome checks for sketch 074 (the editor's header). Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/074-admin-header/verify.js
   Env: PLAYWRIGHT_CORE, SKETCH_URL, SHOTS_DIR (default <os tmp>/sketch-074-shots).

   ROUND 2. Round 1's H1 and H3 are gone along with their comparison checks — their question is answered
   and their measurements live in the README. What is on screen is the decision, not a menu of them.

   `HOY` — the three-piece chrome 073 ships — stays, and every assertion claiming "N1 does not do X" is
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

const ALL = ['N1', 'HOY'];

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
    await set('N1', 'no_bgg_id');  const n1 = await measure();
    ok(hoy.hdrH === 53 && hoy.backH >= 44,
      `NEGATIVE TEST — HOY really does stack a ${hoy.hdrH}px wordmark header above a ${hoy.backH}px in-page back row (${hoy.total}px before the game's name)`);
    ok(n1.hdrH === 0 && n1.backH === 0 && n1.tbarH === 56,
      `N1: one 56px top bar replaces both (hdr ${n1.hdrH}, back row ${n1.backH})`);
    ok(n1.total < hoy.total, `N1: ${hoy.total - n1.total}px of chrome given back (${hoy.total} → ${n1.total})`);
  }

  /* ================= 2. the back affordance exists once ================= */
  {
    const backs = () => J(() => [...document.querySelectorAll('.back, .pb-back, .tb-back')].filter(el => el.offsetParent !== null).length);
    await set('HOY', 'no_bgg_id'); const h = await backs();
    ok(h === 2, `NEGATIVE TEST — HOY really does carry ${h} back controls for one destination (expected 2)`);
    await set('N1', 'no_bgg_id'); const n = await backs();
    ok(n === 1, `N1: exactly one back control (${n})`);
  }

  /* ================= 3. N1 has no bottom bar, in any of the eight situations =================
     Round 1's H1 kept one and split the action area in 3 of 8; worse, `Descartar` was pushed into R359 —
     the exact edge `Guardar` held in the other five — so the editor taught "bottom-right is safe" and then
     put the undo-everything button there. N1 deletes the bar outright. */
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
      await set('N1', s.st, s.cy, s.d);
      barSeen += await J(() => document.getElementById('savebar').classList.contains('on') ? 1 : 0);
    }
    ok(barSeen === 0, `N1: the bottom bar never appears (${barSeen}/8)`);
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
      await set('N1', s.st, s.cy, s.d);
      const r = await slot();
      if (!r) { ok(false, `N1 · ${s.k}: the slot is EMPTY — it must always hold a control`); continue; }
      if (r.dis) dead.push(s.k);
      if (r.label === s.want) labelled++;
      ok(r.dis === s.dead, `N1 · ${s.k}: "${r.label}" ${r.dis ? 'disabled' : 'enabled'} (expected ${s.dead ? 'disabled' : 'enabled'})`);
    }
    ok(dead.length === 1 && dead[0] === 'pub·con-datos·limpio',
      `N1: the slot is dead in ${dead.length}/8 — ${dead.join(', ')} — and only where nothing is pending (d42 allowed 0; it rejected 4)`);
    ok(labelled === 8, `N1: every situation shows the verb d42 says is next (${labelled}/8)`);
  }

  /* ================= 13. the CTA does not move when the title arrives =================
     The title is opacity-0 at rest, NOT display:none, so it keeps its flex space and the CTA is pinned at
     every scroll offset. If it ever collapsed, the CTA would slide left at rest and jump right on scroll —
     d42's "the thing to tap is moving" defect, reintroduced through the fade.
     NEGATIVE-TESTED by collapsing the title on purpose. */
  {
    await set('N1', 'enriched');
    const at = () => J(() => { const b = document.querySelector('.tb-act .btn'); return Math.round(b.getBoundingClientRect().right); });
    const rest = await at();
    await toBottom(); await p.waitForTimeout(220);
    const scrolled = await at();
    ok(rest === scrolled, `N1: the CTA's right edge is R${rest} at rest and R${scrolled} scrolled — it does not move when the title arrives`);
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
    await set('N1', 'enriched');
    const atRest = await nameCount();
    await p.screenshot({ path: path.join(OUT, '14-n1-reposo.png') });
    const y = await toBottom(); await p.waitForTimeout(240);
    ok(y > 200, `N1: the page really scrolls (${y}px) — without this the next check passes vacuously`);
    const atBottom = await nameCount();
    await p.screenshot({ path: path.join(OUT, '14-n1-scrolleado.png') });
    ok(atRest === 2, `N1 at rest: the game's name is on screen ${atRest}× (the 22px head + the Nombre row) — round 1 had 3, the bar's copy is gone`);
    ok(atBottom >= 1, `N1 scrolled to the bottom: the name is back, in the bar (${atBottom}× on screen) — D-19n satisfied by a bar that was already there`);
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
    await set('N1', 'enriched', 'published', true);
    /* a clean editor must NOT confront you with a dialog — otherwise it is noise on 385 healthy games */
    await set('N1', 'enriched');
    await J(() => document.getElementById('tbback').click());
    await p.waitForTimeout(220);
    const cleanOpened = await J(() => document.getElementById('dlg').classList.contains('open'));
    ok(!cleanOpened, `N1: leaving a CLEAN editor does not confirm — no dialog on the 385 healthy games`);

    await set('N1', 'enriched', 'published', true);
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
    ok(!!dlg, `N1: leaving a DIRTY editor opens the confirmation`);
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
      await set('N1', s.st, s.cy, s.d);
      seen += await J(() => [...document.querySelectorAll('#tbar button, #savebar button')]
        .filter(b => b.offsetParent !== null && /descartar/i.test(b.textContent)).length);
    }
    ok(seen === 0, `N1: "Descartar" appears ${seen} times in the permanent chrome — it lives only in the dialog`);
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
    await set('N1', 'no_bgg_id');
    const c = await floor();
    const cta = c.find(x => /vincular/i.test(x.n));
    ok(cta && cta.h === 36, `N1: the CTA is ${cta && cta.h}px tall — 64% of the 56px bar, against round 1's 44px (79%)`);
    ok(cta && cta.hitAbove && cta.hitBelow,
      `N1: the CTA's hit box reaches 4px above AND below the visible button — the 44px floor is real, not drawn`);
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
    await set('N1', 'enriched');
    await J(() => document.querySelector('[data-edit="name"]').click());
    await p.waitForTimeout(220);
    await p.click('#s-name');
    await p.keyboard.type(' II');
    await p.waitForTimeout(220);
    const step = await J(() => {
      const b = document.querySelector('.tb-act .btn');
      return { label: b.textContent.trim(), dis: !!b.disabled, title: document.getElementById('tbt').textContent };
    });
    ok(step.label === 'Guardar' && !step.dis, `N1: typing flips the slot to an enabled "${step.label}" — the CTA IS the unsaved-changes signal`);
    ok(/ II$/.test(step.title), `N1: the bar's title tracks the name being typed ("${step.title}")`);
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

  /* ================= 17. screenshots — LOOK AT THEM =================
     The house rule that has caught what the numbers could not, every round. `published · no_bgg_id · clean`
     IS the 49 real games, the row that decided d42. Both themes, because the last two palette defects in
     this project were dark-only. */
  {
    const theme = async t => { await J(tt => { document.querySelector(`[data-theme-set="${tt}"]`).click(); }, t); await p.waitForTimeout(90); };
    for (const th of ['light', 'dark']) {
      await theme(th);
      for (const v of ALL) {
        await set(v, 'no_bgg_id'); await p.screenshot({ path: path.join(OUT, `17-${th}-${v}-los-49.png`) });
        await set(v, 'enriched', 'published', true); await p.screenshot({ path: path.join(OUT, `17-${th}-${v}-sucio.png`) });
      }
      await set('N1', 'enriched'); await p.screenshot({ path: path.join(OUT, `17-${th}-N1-nada-pendiente.png`) });
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
