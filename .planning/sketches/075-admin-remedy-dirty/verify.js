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

const VARS = ['V1', 'V2', 'V3', 'V4'];
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

  /* `pol` defaults to 'swap' — d44 as settled — so every check written before round 3 keeps measuring
     the incumbent and cannot silently start measuring the new policy. */
  const set = async (v, s, cy = 'published', makeDirty = false, pol = 'swap') => {
    await J(([vv, ss, cc, pp]) => {
      document.querySelector(`[data-var="${vv}"]`).click();
      document.querySelector(`[data-cta="${pp}"]`).click();
      document.querySelector(`[data-st="${ss}"]`).click();
      document.querySelector(`[data-cy="${cc}"]`).click();
      document.getElementById('scroller').scrollTop = 0;
    }, [v, s, cy, pol]);
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
      || document.getElementById('stbtn')
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
      where: el.id === 'rmd' ? 'diagnóstico' : el.id === 'stbtn' ? 'diagnóstico-tap' : el.dataset.edit === 'bgg_id' ? 'fila' : 'barra'
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
    ok(m.V4 === 3, `V4 · remedy reachable while dirty on 3/3 broken states (${m.V4}) — the diagnosis itself`);
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
    ok(bad.length === 0, `d44's slot is identical in all ${VARS.length} variants across d42's 8 situations (${bad.length ? bad.join('; ') : VARS.length * 8 + '/' + VARS.length * 8})`);
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
    await set('V4', 'no_bgg_id', 'published', false);
    const n3 = await J(() => {
      const vis = el => el && el.offsetParent !== null;
      const bar = [...document.querySelectorAll('.tbar [data-act="open-link"]')].filter(vis).length;
      const diag = [...document.querySelectorAll('#stbtn')].filter(vis).length;
      return { bar, diag, total: bar + diag };
    });
    ok(n3.total === 2, `V4 · COST — while clean the remedy is reachable twice too (barra ${n3.bar} + diagnóstico ${n3.diag}), the same charge as V3. d44 is left intact; removing the remedy from the CTA is check 22's number.`);
  }

  /* 14. The diagnosis copy is untouched by the variant that answers it. If V2 had reworded the accusation
     it would be answering a different sentence than V1 shows, and the comparison would be rigged. */
  {
    const read = () => J(() => { const el = document.querySelector('.st .sx'); if (!el) return null;
      const c = el.cloneNode(true); const r = c.querySelector('#rmd'); if (r) r.remove();
      return c.textContent.replace(/\s+/g, ' ').trim(); });
    const out = [];
    for (const v of VARS) { await set(v, 'no_bgg_id', 'published', true); out.push(await read()); }
    ok(new Set(out).size === 1, `the d38 copy is identical in all four variants (${new Set(out).size} distinct) — V2 adds an action below it and changes not a word`);
  }

  /* 15. The top bar still has ONE back control (d43), in every variant — negative-tested against HOY,
     which really does carry two. This is the guard that caught 074's `[hidden]` specificity defect. */
  {
    const backs = () => J(() => [...document.querySelectorAll('#tbback, .pb-back, #back, .back')].filter(el => el && el.offsetParent !== null).length);
    let one = 0;
    for (const v of VARS) { await set(v, 'no_bgg_id'); if (await backs() === 1) one++; }
    ok(one === VARS.length, `one back control in every variant (${one}/${VARS.length}) — d43`);
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

  /* 18. V4's tap target, against V2's button. The exchange V4 makes for having no control container:
     the whole diagnosis is the target instead of a 44px pill. Fitts's law, measured not asserted. */
  {
    await set('V4', 'no_bgg_id', 'published', true);
    const a = await J(() => { const r = document.getElementById('stbtn').getBoundingClientRect(); return { w: Math.round(r.width), h: Math.round(r.height), area: Math.round(r.width * r.height) }; });
    await set('V2', 'no_bgg_id', 'published', true);
    const b = await J(() => { const r = document.getElementById('rmd').getBoundingClientRect(); return { w: Math.round(r.width), h: Math.round(r.height), area: Math.round(r.width * r.height) }; });
    ok(a.area > b.area * 2, `V4's tap target is ${a.w}×${a.h} (${a.area}px²) against V2's ${b.w}×${b.h} (${b.area}px²) — ${(a.area / b.area).toFixed(1)}× the area`);
  }

  /* 19. THE AFFORDANCE, as the only falsifiable question available: is there ANY rendered difference
     between the variant where the diagnosis is the remedy and the variant where it does nothing?
     A true pixel diff — decoded to RGBA, not compared as PNG bytes, because compression rewrites the
     whole stream on a 1px shift and the byte count says nothing.

     DRAWN PURE FIRST, this returned **0 of 270000**. Identical, clean and dirty. That is why the band
     exists, and the negative test below keeps the result alive by stripping `.band` and asserting the
     diff collapses back to 0. Geometry is asserted first: two of my own defects (a `font` shorthand that
     reset `line-height`, and one-sided padding) moved the spine 8px, and a diff would have reported them
     as an affordance. */
  {
    const clip = { x: 0, y: 100, width: 375, height: 180 };
    const geo = () => J(() => { const R = e => e ? Math.round(e.getBoundingClientRect().top) : null;
      return { sx: R(document.querySelector('.st .sx')), gl: R(document.querySelector('.glabel')), nm: R(document.querySelector('[data-edit="name"]')) }; });
    const shot = async (v, strip) => {
      await set(v, 'no_bgg_id', 'published', true);
      if (strip) { await J(() => document.getElementById('stbtn').classList.remove('band')); await p.waitForTimeout(80); }
      return (await p.screenshot({ clip })).toString('base64');
    };
    await set('V1', 'no_bgg_id', 'published', true); const g1 = await geo();
    await set('V4', 'no_bgg_id', 'published', true); const g4 = await geo();
    ok(g1.sx === g4.sx && g1.gl === g4.gl && g1.nm === g4.nm,
      `V4 moves no text — the spine sits where V1 puts it (${JSON.stringify(g1)} vs ${JSON.stringify(g4)}), d29's reason for a band on a pseudo`);

    const a = await shot('V1', false), b = await shot('V4', false), c = await shot('V4', true);
    const q = await ctx.newPage(); await q.goto('about:blank');
    const diff = (x, y) => q.evaluate(async ([m, n]) => {
      const load = z => new Promise(r => { const i = new Image(); i.onload = () => r(i); i.src = 'data:image/png;base64,' + z; });
      const [ia, ib] = await Promise.all([load(m), load(n)]);
      const cv = document.createElement('canvas'); cv.width = ia.width; cv.height = ia.height; const g = cv.getContext('2d');
      g.drawImage(ia, 0, 0); const da = g.getImageData(0, 0, cv.width, cv.height).data;
      g.clearRect(0, 0, cv.width, cv.height); g.drawImage(ib, 0, 0); const db = g.getImageData(0, 0, cv.width, cv.height).data;
      let d = 0; for (let i = 0; i < da.length; i += 4) { const e = Math.abs(da[i] - db[i]) + Math.abs(da[i + 1] - db[i + 1]) + Math.abs(da[i + 2] - db[i + 2]); if (e > 8) d++; }
      return { diffPx: d, totalPx: da.length / 4 };
    }, [x, y]);
    const withBand = await diff(a, b), without = await diff(a, c);
    await q.close();
    ok(withBand.diffPx > 2000, `V4 IS visibly distinguishable from V1 — ${withBand.diffPx} of ${withBand.totalPx}px differ over the diagnosis`);
    ok(without.diffPx === 0, `NEGATIVE TEST — strip the band and V4 is PIXEL-IDENTICAL to V1 (${without.diffPx}px). The pure version had zero affordance, which is the finding that forced the band.`);
  }

  /* 20. The accessible name carries BOTH halves. An `aria-label` naming only the action would hide the
     diagnosis from assistive tech, which is the one thing this block exists to deliver. */
  {
    await set('V4', 'no_bgg_id', 'published', true);
    const n = await J(() => document.getElementById('stbtn').textContent.replace(/\s+/g, ' ').trim());
    ok(/no está vinculado/.test(n) && /tocá para/.test(n), `V4's accessible name is the diagnosis AND the action ("…${n.slice(-34)}")`);
  }

  /* 21. THE INVISIBLE DOT — inherited, not this sketch's. `.st.warn .dot` was `var(--color-accent)`,
     which the theme does not define (it is `--color-accent-bg`/`--color-accent-text`, and default.css:22
     records the rename), so it computed to `rgba(0,0,0,0)`: an 8px transparent hole, in 073, 074 and 075.
     `warn` is `no_bgg_id` — 41 of the 49. `.st.bad` used `--color-danger`, which IS defined, so 8 games
     showed a dot and 41 did not. d40 says status is a dot + text; on the majority it has been text. */
  {
    const theme = async t => { await J(tt => { document.querySelector(`[data-theme-set="${tt}"]`).click(); }, t); await p.waitForTimeout(90); };
    const bad = [];
    for (const th of ['light', 'dark']) {
      await theme(th);
      for (const st of BROKEN) {
        await set('V1', st);
        const c = await J(() => { const d = document.querySelector('.st .dot'); return d ? getComputedStyle(d).backgroundColor : 'none'; });
        if (/rgba\(0, 0, 0, 0\)|transparent/.test(c)) bad.push(`${th}/${st}`);
      }
    }
    ok(bad.length === 0, `no diagnosis dot computes transparent, in either theme (${bad.length ? bad.join(', ') : '6/6'})`);
    await theme('light');
    await set('V1', 'no_bgg_id');
    const neg = await J(() => { const d = document.querySelector('.st .dot'); d.style.background = 'var(--color-accent)'; return getComputedStyle(d).backgroundColor; });
    ok(/rgba\(0, 0, 0, 0\)/.test(neg), `NEGATIVE TEST — \`var(--color-accent)\` really does compute to ${neg}, so check 21 can fail`);
    await set('V1', 'no_bgg_id');
  }

  /* 22. The number V4 needs and does not have: what would it cost to make the diagnosis the ONLY home,
     i.e. drop the remedy from the CTA? Computed by overriding `primary()`, NOT drawn — it reopens d44,
     which this round is not allowed to touch. d42 rejected 4 of 8 dead; round 2 accepted 1 of 8. */
  {
    await set('V4', 'no_bgg_id', 'published', false);
    const dead = await J((sits) => {
      const orig = window.primary;
      window.primary = function () {
        if (dirty()) return { label: 'Guardar', id: 'save', dis: false };
        if (CY === 'draft') return { label: 'Publicar', id: 'publish', dis: !hasData() };
        return null;                       /* the remedy no longer offered here */
      };
      let n = 0;
      for (const s of sits) { ST = s.st; CY = s.cy; loadState(); if (s.d) G.is_expansion = !START.is_expansion; const p2 = topSlot(); if (p2.dis) n++; }
      window.primary = orig; ST = 'no_bgg_id'; CY = 'published'; loadState(); render();
      return n;
    }, SITS);
    ok(dead >= 1, `V4-only (remedy dropped from the CTA) would leave the slot dead in ${dead} of 8 — d42 rejected 4, d44 accepted 1. Named, not drawn: it reopens d44.`);
  }

  /* ============================ ROUND 3: WHAT THE HEADER CTA IS FOR ============================
     23. THE TAXONOMY, asserted rather than accepted. The developer's claim is that `Vincular` is not the
     same kind of thing as `Guardar` — it opens a sheet, it does not commit the page. Checked against the
     artefact: `remedy()` returns `open-link` (-> idSheet(), a disclosure) for two of the three broken
     states and `retry` (-> fires the job) for the third. So the slot has been holding disclosures and
     page-commits interchangeably, under one name. */
  {
    const kinds = await J(() => {
      const out = {};
      for (const st of ['no_bgg_id', 'bgg_missing', 'failed']) { const o = ST; ST = st; const r = remedy(); out[st] = r.act; ST = o; }
      return out;
    });
    const opens = Object.values(kinds).filter(k => k === 'open-link').length;
    ok(opens === 2, `\`remedy()\` returns two KINDS under one name: ${JSON.stringify(kinds)} — ${opens} disclosures (open a sheet) and ${3 - opens} action`);
  }

  /* 24. Under 'page' the slot holds ONLY what commits the page — never a sheet-opener — in every
     situation and every variant. Negative-tested against 'swap', which really does put one there. */
  {
    let leaked = [];
    for (const v of VARS) for (const s of SITS) {
      await set(v, s.st, s.cy, s.d, 'page');
      const a = await J(() => { const b = document.querySelector('.tbar .btn'); return b ? { label: b.textContent.trim(), act: b.dataset.act || null } : null; });
      if (a && a.act) leaked.push(`${v}/${s.k}: ${a.label} (${a.act})`);
    }
    ok(leaked.length === 0, `'page' · the CTA never holds a sheet-opener (${leaked.length ? leaked.join('; ') : VARS.length * 8 + ' situations clean'})`);
    await set('V4', 'no_bgg_id', 'published', false, 'swap');
    const sw = await J(() => { const b = document.querySelector('.tbar .btn'); return b ? b.dataset.act || null : null; });
    ok(sw === 'open-link', `NEGATIVE TEST — 'swap' (d44) really does put a sheet-opener in the CTA (act="${sw}"), so check 24 can fail`);
  }

  /* 25. The count, and what changes is its MEANING. d42 rejected 4-of-8 because a dead `Guardar` there
     "demoted the real next step to a ghost" — which assumes the remedy wanted that slot. Under 'page' it
     never wanted it, so the same number stops describing an inverted hierarchy and starts describing a
     page with nothing to commit. The number is asserted; the reading is the developer's call. */
  {
    const count = async pol => {
      let n = 0, which = [];
      for (const s of SITS) { await set('V4', s.st, s.cy, s.d, pol);
        const d = await J(() => { const b = document.querySelector('.tbar .btn'); return !!(b && b.disabled); });
        if (d) { n++; which.push(s.k); } }
      return { n, which };
    };
    const sw = await count('swap'), pg = await count('page');
    ok(sw.n === 1, `'swap' (d44) · dead in ${sw.n} of 8 (${sw.which.join(', ')})`);
    ok(pg.n === 4, `'page' · dead in ${pg.n} of 8 (${pg.which.join(', ')}) — d42's rejected count, under a premise that makes it accurate rather than inverted`);
  }

  /* 26. WHAT IT BUYS: V4's only charged cost disappears. Round 2 charged V4 with the remedy being
     reachable TWICE while clean (barra 1 + diagnóstico 1). Under 'page' the bar never holds it, so the
     remedy has exactly one home — clean AND dirty, the same one, never moving. */
  {
    const n = async (pol, d) => { await set('V4', 'no_bgg_id', 'published', d, pol);
      return J(() => { const vis = el => el && el.offsetParent !== null;
        return [...document.querySelectorAll('.tbar [data-act="open-link"], #stbtn')].filter(vis).length; }); };
    const a = await n('swap', false), b = await n('page', false), c = await n('page', true);
    ok(a === 2 && b === 1 && c === 1,
      `V4 · 'swap' reaches the remedy twice while clean (${a}); 'page' reaches it exactly once, clean (${b}) and dirty (${c}) — one home, never moving. Round 2's only charged cost, dissolved.`);
  }

  /* 27. THE COMBINATION THAT MUST NOT SHIP: 'page' with no body home leaves the remedy reachable from
     NOWHERE, in any state. Asserted so the two axes cannot be set independently by mistake. */
  {
    let gone = 0;
    for (const st of BROKEN) for (const d of [false, true]) {
      await set('V1', st, 'published', d, 'page');
      const r = await reach();
      if (!r.rendered) gone++;
    }
    ok(gone === 6, `V1 + 'page' leaves the remedy reachable from nowhere in ${gone}/6 broken states — the two axes are NOT independent: 'page' requires a body home`);
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
