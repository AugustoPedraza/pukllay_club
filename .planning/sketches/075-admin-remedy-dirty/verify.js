/* Headless-Chrome checks for sketch 075 (the remedy while dirty). Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/075-admin-remedy-dirty/verify.js
   Env: PLAYWRIGHT_CORE, SKETCH_URL, SHOTS_DIR (default <os tmp>/sketch-075-shots).

   ROUND 4 of the editor's lineage (071 -> 072 -> 073 -> 074 -> here). 074's weight checks (18-22) are gone
   with their variants: d46 settled W3 Texto and re-running its comparison would be measuring a decision.
   What is kept from 074 is only what this round could BREAK — the CTA's fixed right edge, the 1-of-8 dead
   slot, the touch floors, the top bar's single back control. Those are inheritance guards, not this
   round's question, and they are written against `HOY` so they can still fail.

   THE ROUND'S QUESTION: where the remedy lives while the CTA slot is taken.
     V1 nowhere (the incumbent) · V2 in the d38 diagnosis · V3 a `bgg_id` row in the spine · HOY 073.

   Traps this file is written around, all of which have produced fake findings in this project:
     · CDP synthesizeScrollGesture yields Δ0 here — scroll is driven by setting `scroller.scrollTop`.
     · CDP touch does not set `:active` — nothing here asserts a press state.
     · Visibility is `offsetParent !== null`, NEVER `el.hidden` or the element's own computed display.
     · "On screen" is NOT `rect.bottom <= scroller.bottom`. The 67px tab bar OVERLAYS the scroller, so the
       scroller's own rect reports 740 while the eye stops at 673. Measuring against the scroller made V3's
       row look 21px short when it is in fact ENTIRELY behind the tab bar. Every fold assertion below
       measures against `.tabs`'s top AND hit-tests the control's centre with `elementFromPoint`.
     · Touch floors are hit-tested, and the hit must BE the control or a descendant, so a parent cannot
       swallow the probe.
     · A guard that reads an element at `opacity: 0` returns tidy numbers about nothing (074's check 20).
       Visibility is asserted before any geometry is read from the title. */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();
const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/075-admin-remedy-dirty/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-075-shots'); fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);

const VARS = ['V1', 'V2', 'V3'];
const BROKEN = ['no_bgg_id', 'bgg_missing', 'failed'];

/* d42's eight situations. `dead` marks the ONE where nothing is pending — the only place d44's slot is
   allowed to hold a disabled control. Encoded here so check 4 fails loudly if it ever becomes two. */
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
      /* through the real UI — d41 deleted the sheets' commit buttons, so picking the other value commits
         and closes in one tap. Going through the UI rather than poking `G` is what makes the dirty state
         the same one a person would produce. */
      await J(() => document.querySelector('[data-edit="is_expansion"]').click());
      await p.waitForTimeout(140);
      await J(() => document.querySelector('[data-pick="is_expansion"][data-val="true"]').click());
      await p.waitForTimeout(180);
      await J(() => { document.getElementById('scroller').scrollTop = 0; });
    }
    await cool();
  };
  const toBottom = () => J(() => { const s = document.getElementById('scroller'); s.scrollTop = s.scrollHeight; return s.scrollTop; });

  /* THE reachability probe. Three independent facts, because each alone has lied in this project:
       rendered   — it is in the DOM and has a layout box (offsetParent), not `hidden`, not display:none
       visible    — its box is above the tab bar's top edge, which is where the eye actually stops
       tappable   — elementFromPoint at its centre returns it or a descendant, so nothing overlays it */
  const reach = () => J(() => {
    const el = document.getElementById('rmd')
      || document.querySelector('[data-edit="bgg_id"]')
      || document.querySelector('.tbar [data-act], .savebar [data-act]');
    if (!el || el.offsetParent === null) return { rendered: false, visible: false, tappable: false };
    const r = el.getBoundingClientRect();
    const visBottom = document.querySelector('.tabs').getBoundingClientRect().top;
    const cx = Math.round(r.left + r.width / 2), cy = Math.round(r.top + r.height / 2);
    const hit = document.elementFromPoint(cx, cy);
    return {
      rendered: true,
      visible: r.top < visBottom && r.bottom > 0,
      fullyVisible: r.bottom <= visBottom && r.top >= 0,
      tappable: !!hit && (hit === el || el.contains(hit)),
      top: Math.round(r.top), bottom: Math.round(r.bottom), visBottom: Math.round(visBottom),
      where: el.id === 'rmd' ? 'diagnóstico' : el.dataset.edit === 'bgg_id' ? 'fila' : 'barra'
    };
  });

  /* ============================ 1. THE ROUND'S OWN QUESTION ============================
     The premise, restated as an assertion so it cannot rot: on the INCUMBENT the remedy is not merely
     demoted while dirty, it is unreachable — at BOTH scroll extremes, on all three broken states. */
  {
    let gone = 0, there = 0;
    for (const st of BROKEN) {
      await set('V1', st, 'published', false);
      const clean = await reach();
      if (clean.rendered && clean.tappable) there++;
      await set('V1', st, 'published', true);
      const top = await reach();
      await toBottom(); await p.waitForTimeout(160);
      const bot = await reach();
      if (!top.rendered && !bot.rendered) gone++;
    }
    ok(there === 3, `V1 · the remedy IS reachable while clean, on all three broken states (${there}/3)`);
    ok(gone === 3, `V1 · the remedy is UNREACHABLE while dirty, at rest AND at full scroll, on all three (${gone}/3) — the round's premise`);
  }

  /* 2. …and the accusation stays, word for word. This is the asymmetry the round is about: if the
     diagnosis softened or disappeared while dirty there would be no problem to solve. */
  {
    const read = () => J(() => { const el = document.querySelector('.st'); return el && el.offsetParent !== null ? el.textContent.replace(/\s+/g, ' ').trim() : null; });
    let same = 0;
    for (const st of BROKEN) {
      await set('V1', st, 'published', false); const a = await read();
      await set('V1', st, 'published', true);  const b = await read();
      if (a && b && a === b) same++;
    }
    ok(same === 3, `V1 · the d38 diagnosis is byte-identical clean vs dirty on all three broken states (${same}/3) — a permanent accusation with the remedy removed`);
  }

  /* 3. V2 and V3 answer it; V1 does not. The headline comparison, one row per variant. */
  {
    const rows = [];
    for (const v of VARS) {
      let n = 0;
      for (const st of BROKEN) { await set(v, st, 'published', true); const r = await reach(); if (r.rendered && r.tappable) n++; }
      rows.push([v, n]);
    }
    const m = Object.fromEntries(rows);
    ok(m.V1 === 0, `V1 · remedy reachable while dirty on 0/3 broken states (${m.V1}) — the control`);
    ok(m.V2 === 3, `V2 · remedy reachable while dirty on 3/3 broken states (${m.V2})`);
    ok(m.V3 === 0, `V3 · remedy NOT tappable at rest while dirty (${m.V3}/3) — the row is below the tab bar; see check 8`);
  }

  /* ============================ INHERITANCE: what this round must not break ============================
     4. d44's slot, unchanged. `primary()` and `topSlot()` are supposed to be byte-identical across the
     three variants — if V2 or V3 had quietly altered what the CTA holds, the round would be comparing two
     decisions rather than three homes for one. Asserted per variant, not once. */
  {
    let bad = [], deadCount = {};
    for (const v of VARS) {
      deadCount[v] = 0;
      for (const s of SITS) {
        await set(v, s.st, s.cy, s.d);
        const got = await J(() => { const b = document.querySelector('.tbar .btn'); return b ? { label: b.textContent.trim(), dis: b.disabled === true } : null; });
        if (!got || got.label !== s.want) bad.push(`${v}/${s.k}: ${got ? got.label : 'NONE'} ≠ ${s.want}`);
        if (got && got.dis) { deadCount[v]++; if (!s.dead) bad.push(`${v}/${s.k}: dead slot in a situation that has something pending`); }
      }
    }
    ok(bad.length === 0, `d44's slot is identical in all three variants across d42's 8 situations (${bad.length ? bad.join('; ') : '24/24'})`);
    ok(VARS.every(v => deadCount[v] === 1), `the slot is dead in exactly 1 of 8, in every variant (${JSON.stringify(deadCount)}) — d42 rejected 4, and this is the guard that stops it drifting back`);
  }

  /* 5. d42's fixed right edge, held literally since d46. The remedy moving to a second container must not
     drag the CTA off R359 — and V2's action must NOT land on that edge either, or the page would have two
     right-edge actions whose relationship is unstated. */
  {
    const edge = () => J(() => { const b = document.querySelector('.tbar .btn'); return b ? Math.round(b.getBoundingClientRect().right) : null; });
    const seen = new Set();
    for (const v of VARS) for (const s of SITS) { await set(v, s.st, s.cy, s.d); seen.add(await edge()); }
    ok(seen.size === 1 && seen.has(359), `the CTA's right edge is R359 in every variant and every situation (${[...seen].join(', ')})`);

    await set('V2', 'no_bgg_id', 'published', true);
    const r = await J(() => { const b = document.getElementById('rmd'); return b ? Math.round(b.getBoundingClientRect().right) : null; });
    ok(r !== null && r < 300, `V2 · the remedy does NOT sit on the CTA's edge (R${r} vs R359) — it is left-aligned on the keyline, d16`);
  }

  /* 6. Touch floors, hit-tested rather than measured. A 44px height that something else overlays is not
     a 44px target. */
  {
    await set('V2', 'no_bgg_id', 'published', true);
    const v2 = await J(() => {
      const b = document.getElementById('rmd'); const r = b.getBoundingClientRect();
      const probe = (x, y) => { const h = document.elementFromPoint(Math.round(x), Math.round(y)); return !!h && (h === b || b.contains(h)); };
      return { h: Math.round(r.height), top: probe(r.left + r.width / 2, r.top + 3), bot: probe(r.left + r.width / 2, r.bottom - 3) };
    });
    ok(v2.h >= 44 && v2.top && v2.bot, `V2 · the remedy is ${v2.h}px and hit-tests at both its top and bottom edge`);

    await set('V3', 'no_bgg_id', 'published', true);
    await toBottom(); await p.waitForTimeout(180);
    const v3 = await J(() => {
      const b = document.querySelector('[data-edit="bgg_id"]'); if (!b) return null;
      const r = b.getBoundingClientRect();
      const probe = (x, y) => { const h = document.elementFromPoint(Math.round(x), Math.round(y)); return !!h && (h === b || b.contains(h)); };
      return { h: Math.round(r.height), top: probe(r.left + r.width / 2, r.top + 3), bot: probe(r.left + r.width / 2, r.bottom - 3) };
    });
    ok(v3 && v3.h >= 44 && v3.top && v3.bot, `V3 · the BGG row is ${v3 ? v3.h : '?'}px and hit-tests top and bottom, once scrolled to`);
  }

  /* 7. d34, asserted on the new row: a row that opens a sheet carries NO chevron. V3's whole claim is
     that it reuses the spine's anatomy rather than inventing one, so this is the anatomy check. */
  {
    await set('V3', 'no_bgg_id', 'published', false);
    const anat = await J(() => {
      const row = document.querySelector('[data-edit="bgg_id"]');
      if (!row) return null;
      const spine = document.querySelector('[data-edit="name"]');
      const cs = getComputedStyle(row), sp = getComputedStyle(spine);
      return {
        svg: row.querySelectorAll('svg').length,
        cls: row.className,
        sameHeight: Math.round(row.getBoundingClientRect().height) === Math.round(spine.getBoundingClientRect().height),
        sameLeft: Math.round(row.getBoundingClientRect().left) === Math.round(spine.getBoundingClientRect().left),
        sameFont: cs.fontSize === sp.fontSize,
        opensSheet: true
      };
    });
    ok(anat && anat.svg === 0, `V3 · the BGG row carries no glyph (${anat ? anat.svg : '?'} svg) — d34, a row that opens a sheet has no chevron`);
    ok(anat && anat.cls.includes('frow') && anat.sameHeight && anat.sameLeft, `V3 · the BGG row IS a spine row — same class, height and left keyline as \`Nombre\``);
  }

  /* 8. THE FOLD. V3's claim is "always one tap away". Measured against the tab bar's top edge — not the
     scroller's, which reports 740 while the eye stops at 673 — and hit-tested. This is the check that
     found V3's row is not merely clipped but entirely behind the tab bar. */
  {
    const rows = [];
    for (const v of ['V2', 'V3']) for (const st of BROKEN) {
      await set(v, st, 'published', true);
      const r = await reach();
      rows.push(`${v}/${st}: ${r.where} y${r.top}-${r.bottom} (visible hasta ${r.visBottom}) vis=${r.visible} tap=${r.tappable}`);
    }
    await set('V2', 'no_bgg_id', 'published', true); const a = await reach();
    await set('V3', 'no_bgg_id', 'published', true); const b = await reach();
    ok(a.fullyVisible && a.tappable, `V2 · the remedy is fully above the fold at rest (y${a.top}-${a.bottom}, fold ${a.visBottom})`);
    ok(!b.visible && !b.tappable, `V3 · the BGG row is ENTIRELY below the tab bar at rest (y${b.top}-${b.bottom}, fold ${b.visBottom}) — "one tap away" costs a scroll first`);
    ok(true, `fold detail — ${rows.join(' | ')}`);
  }

  /* 9. THE DATA-LOSS FIX, and its negative test. This is not a variant axis: it is the defect both V2 and
     V3 walk into by making the remedy reachable mid-edit. Linking must SAVE the club edit, not silently
     discard it. Negative-tested by neutering `commitClubEdit` and the restore, which is what 074 did. */
  {
    await set('V2', 'no_bgg_id', 'published', true);
    const before = await J(() => document.querySelector('[data-edit="is_expansion"] .fr-v').textContent.trim());
    await J(() => document.getElementById('rmd').click());
    await p.waitForTimeout(200);
    await J(() => { document.getElementById('s-bgg').value = '224517'; document.querySelector('[data-commit="bgg_id"]').click(); });
    await p.waitForTimeout(280);
    /* the enrichment ARRIVES — not the tool panel's fixture switch, which calls loadState() and would be
       measuring "open a different game" rather than "the data came back while I was editing" */
    await J(() => enrichmentArrived());
    await p.waitForTimeout(200);
    const after = await J(() => { const el = document.querySelector('[data-edit="is_expansion"] .fr-v'); return el ? el.textContent.trim() : 'row gone'; });
    ok(before === 'Sí' && after === 'Sí', `linking from V2's remedy PRESERVES the unsaved club edit ("${before}" → "${after}")`);

    /* negative test — put 074's behaviour back and confirm the check can fail */
    await set('V2', 'no_bgg_id', 'published', true);
    await J(() => { window.__cce = window.commitClubEdit; window.commitClubEdit = () => false; window.__ck = window.CLUB_KEYS; });
    const broke = await J(async () => {
      /* reproduce 074's commitId verbatim: loadState() with no capture/restore */
      const id = 224517;
      G.bgg_id = id; START.bgg_id = id;
      ST = 'pending'; FIX.pending.bgg_id = id; FIX.pending.name = G.name;
      loadState(); G.bgg_id = id; START.bgg_id = id;
      enrichmentArrived();
      const el = document.querySelector('[data-edit="is_expansion"] .fr-v');
      return el ? el.textContent.trim() : 'row gone';
    });
    ok(broke === 'No', `NEGATIVE TEST — 074's commitId really does wipe the edit ("${broke}"), so check 9 can fail`);
    await J(() => { window.commitClubEdit = window.__cce; });
  }

  /* 10. …and the same for `Reintentar`, which had the identical shape and is the remedy on `failed`. */
  {
    await set('V2', 'failed', 'published', true);
    const before = await J(() => document.querySelector('[data-edit="is_expansion"] .fr-v').textContent.trim());
    await J(() => document.getElementById('rmd').click());
    await p.waitForTimeout(280);
    await J(() => enrichmentArrived());
    await p.waitForTimeout(200);
    const after = await J(() => { const el = document.querySelector('[data-edit="is_expansion"] .fr-v'); return el ? el.textContent.trim() : 'row gone'; });
    ok(before === 'Sí' && after === 'Sí', `Reintentar from V2's remedy also preserves the unsaved edit ("${before}" → "${after}")`);
  }

  /* 11. THE UA BEVEL. `.rmd` is the first control drawn from scratch since `.btn` reset `border: 0`, and
     without that reset the UA paints a `2px outset` bezel — found in the first screenshot, invisible to
     any box-shadow or contrast assertion. Read the computed border-style, not the shadow. */
  {
    await set('V2', 'no_bgg_id', 'published', true);
    const b = await J(() => { const cs = getComputedStyle(document.getElementById('rmd')); return { style: cs.borderTopStyle, width: cs.borderTopWidth, shadow: cs.boxShadow }; });
    ok(b.style === 'none' || b.width === '0px', `V2 · the remedy carries no UA bevel (border: ${b.width} ${b.style})`);
    ok(/inset/.test(b.shadow), `V2 · its container is an inset stroke — 064's Principal, the first time it is actually drawn in the 071-075 lineage`);
  }

  /* 12. V2's honest cost, measured rather than argued: the remedy MOVES between two containers. d42 fixed
     exactly this shape inside the bar ("the thing to tap is moving"); V2 reintroduces it across
     containers. The number is the travel between where it sits clean and where it sits dirty. */
  {
    await set('V2', 'no_bgg_id', 'published', false);
    const clean = await J(() => { const b = document.querySelector('.tbar [data-act]'); const r = b.getBoundingClientRect(); return { x: Math.round(r.left + r.width / 2), y: Math.round(r.top + r.height / 2) }; });
    await set('V2', 'no_bgg_id', 'published', true);
    const dirt = await J(() => { const b = document.getElementById('rmd'); const r = b.getBoundingClientRect(); return { x: Math.round(r.left + r.width / 2), y: Math.round(r.top + r.height / 2) }; });
    const dx = Math.abs(dirt.x - clean.x), dy = Math.abs(dirt.y - clean.y);
    ok(dx > 0 && dy > 0, `V2 · COST — the remedy travels ${dx}px across and ${dy}px down when the edit starts (bar ${clean.x},${clean.y} → diagnóstico ${dirt.x},${dirt.y}). Recorded, not smoothed over.`);
  }

  /* 13. V3's honest cost: while CLEAN the remedy is reachable twice — from the bar and from the row. 074
     round 1 charged exactly this against the duplicated back control, so it is charged here too. */
  {
    await set('V3', 'no_bgg_id', 'published', false);
    const n = await J(() => {
      const vis = el => el && el.offsetParent !== null;
      const bar = [...document.querySelectorAll('.tbar [data-act="open-link"]')].filter(vis).length;
      const row = [...document.querySelectorAll('[data-edit="bgg_id"]')].filter(vis).length;
      return { bar, row, total: bar + row };
    });
    ok(n.total === 2, `V3 · COST — while clean the remedy is reachable twice (bar ${n.bar} + fila ${n.row}). Same charge 074 laid against the duplicated back control.`);
    await set('V2', 'no_bgg_id', 'published', false);
    const n2 = await J(() => {
      const vis = el => el && el.offsetParent !== null;
      return [...document.querySelectorAll('.tbar [data-act="open-link"],#rmd')].filter(vis).length;
    });
    ok(n2 === 1, `V2 · while clean the remedy is reachable exactly once (${n2}) — the understudy stays off until the slot is taken`);
  }

  /* 14. The diagnosis copy is untouched by the variant that answers it. If V2 had reworded the accusation
     it would be answering a different sentence than V1 shows, and the comparison would be rigged. */
  {
    const read = () => J(() => { const el = document.querySelector('.st .sx'); if (!el) return null;
      const c = el.cloneNode(true); const r = c.querySelector('#rmd'); if (r) r.remove();
      return c.textContent.replace(/\s+/g, ' ').trim(); });
    const out = [];
    for (const v of VARS) { await set(v, 'no_bgg_id', 'published', true); out.push(await read()); }
    ok(new Set(out).size === 1, `the d38 copy is identical in all three variants (${new Set(out).size} distinct) — V2 adds an action below it and changes not a word`);
  }

  /* 15. The top bar still has ONE back control (d43), in every variant — negative-tested against HOY,
     which really does carry two. This is the guard that caught 074's `[hidden]` specificity defect. */
  {
    const backs = () => J(() => [...document.querySelectorAll('#tbback, .pb-back, #back, .back')].filter(el => el && el.offsetParent !== null).length);
    let one = 0;
    for (const v of VARS) { await set(v, 'no_bgg_id'); if (await backs() === 1) one++; }
    ok(one === 3, `one back control in every variant (${one}/3) — d43`);
    await set('HOY', 'no_bgg_id');
    await toBottom(); await p.waitForTimeout(200);
    const h = await backs();
    ok(h >= 2, `NEGATIVE TEST — HOY really does carry ${h} back controls at full scroll, so check 15 can fail`);
  }

  /* 17. V2's SHARPEST COST, on d46's own axis. Found in a screenshot, then measured.
     d46 made the top-bar CTA a TEXT button (0px² painted) because in a single-action container weight
     buys nothing and costs the disabled read. 064 makes a content-block action an OUTLINE Principal.
     Follow both rules — which V2 does, correctly — and while dirty the page's PRIMARY is its faintest
     control while the UNDERSTUDY carries the only container on screen. The hierarchy inverts.

     Stated as measured, not as a verdict: this is not a rule violation, it is two rules meeting in a
     situation neither was written for — the same shape as 064-vs-d42's unresolved disabled-button
     conflict that 074 left open. The alternative (a text remedy, 0px² both) removes the inversion and
     costs the affordance: a bare word inside a prose block may not read as a control at all. Not drawn;
     named, because it is the developer's call and not the harness's. */
  {
    await set('V2', 'no_bgg_id', 'published', true);
    const m = await J(() => {
      const area = el => { const r = el.getBoundingClientRect(), cs = getComputedStyle(el), w = r.width, h = r.height;
        if (cs.backgroundColor !== 'rgba(0, 0, 0, 0)') return { painted: Math.round(w * h), kind: 'relleno' };
        if (cs.boxShadow && cs.boxShadow !== 'none' && /inset/.test(cs.boxShadow)) return { painted: Math.round(w * h - (w - 2) * (h - 2)), kind: 'contorno' };
        return { painted: 0, kind: 'texto' }; };
      const cta = document.querySelector('.tbar .btn'), rmd = document.getElementById('rmd');
      return { cta: { l: cta.textContent.trim(), ...area(cta) }, rmd: { l: rmd.textContent.trim(), ...area(rmd) } };
    });
    ok(m.cta.painted < m.rmd.painted,
      `V2 · COST — the hierarchy inverts while dirty: primary "${m.cta.l}" paints ${m.cta.painted}px² (${m.cta.kind}), understudy "${m.rmd.l}" paints ${m.rmd.painted}px² (${m.rmd.kind}). d47 and 064 meeting in a case neither was written for.`);
  }

  /* 16. Screenshots. Every variant, both themes, the dirty broken state the round is about — and then
     looked at, which is the only thing that has reliably caught what these checks are green over. */
  {
    const theme = async t => { await J(tt => { document.querySelector(`[data-theme-set="${tt}"]`).click(); }, t); await p.waitForTimeout(90); };
    for (const th of ['light', 'dark']) {
      await theme(th);
      for (const v of [...VARS, 'HOY']) {
        await set(v, 'no_bgg_id', 'published', false); await p.screenshot({ path: path.join(OUT, `16-${th}-${v}-limpio.png`) });
        await set(v, 'no_bgg_id', 'published', true);  await p.screenshot({ path: path.join(OUT, `16-${th}-${v}-sucio.png`) });
      }
      /* V3 needs a scroll to show its answer at all — that IS the finding, so capture both ends */
      await set('V3', 'no_bgg_id', 'published', true); await toBottom(); await p.waitForTimeout(200);
      await p.screenshot({ path: path.join(OUT, `16-${th}-V3-sucio-scrolled.png`) });
      await set('V2', 'bgg_missing', 'published', true); await p.screenshot({ path: path.join(OUT, `16-${th}-V2-idmalo-sucio.png`) });
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
