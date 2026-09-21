/* Headless-Chrome checks for sketch 076 — slice 1 of the create scenario. Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/076-admin-create-visibility/verify.js
   Env: PLAYWRIGHT_CORE, SKETCH_URL, SHOTS_DIR (default <os tmp>/sketch-076-shots).

   SLICE 1 of the create -> edit -> draft -> failed scenario (the 2026-09-20 handoff). Every earlier sketch in
   this lineage measured STATES; this one measures a TRANSITION, so almost every check below runs BEFORE and
   AFTER one action rather than on a fixture.

   THE ROUND'S QUESTION: after `Agregar` with a BGG id, where does the new game become visible?
     V1 Nada (071 verbatim, the incumbent and the negative-test baseline) · V2 Se abre · V3 Arriba.

   Traps this file is written around — all of which have produced fake findings in this project:
     · The tool panel is `position: fixed` OVER the device at 375px. It swallows `elementFromPoint` probes near
       the top of the page, so it is hidden before any geometry or hit test is read. Check 0 asserts it is
       actually hidden, or every reachability number below would be about the panel.
     · "On screen" is NOT `rect.bottom <= scroller.bottom`. The 67px tab bar OVERLAYS the scroller, so the
       scroller's own rect reports 740 while the eye stops at 673 (075). The fold is `.tabs`'s top.
     · Visible + above the fold is NOT reachable. d17 makes every section caption STICKY, so `Borradores`'
       caption pins under the search and covers the row a scroll just delivered — which is exactly what the
       first drawing of V2 did (y121-185, visible, above the fold, and `elementFromPoint` returned
       `.lhead | BORRADORES 2`). Only a hit test sees it. Check 6 is that hit test and check 7 negative-tests
       the fix by removing it.
     · Visibility is `offsetParent !== null`, never `el.hidden` or the element's own computed display (074).
     · A row that is not in the DOM at all reads as "not visible" through every geometry check without ever
       saying so. Check 1 asserts DOM PRESENCE separately from visibility, because V1's whole defect is
       absence rather than obscurity. */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();
const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/076-admin-create-visibility/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-076-shots'); fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);
const VARS = ['V1', 'V2', 'V3'];

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const errs = [];
  const ctx = await browser.newContext({ viewport: { width: 375, height: 740 }, deviceScaleFactor: 2 });
  const p = await ctx.newPage();
  p.on('pageerror', e => errs.push('pageerror: ' + e.message));
  p.on('console', m => { if (m.type() === 'error' && !/404|Failed to load resource/.test(m.text())) errs.push('console: ' + m.text()); });
  await p.goto(URL, { waitUntil: 'networkidle' });

  /* the tool panel is a fixed overlay on top of `.device` at this width — hide it before anything is measured */
  const hideTools = () => p.evaluate(() => { document.getElementById('tools').style.visibility = 'hidden'; });
  await hideTools();
  ok(await p.evaluate(() => getComputedStyle(document.getElementById('tools')).visibility === 'hidden'),
    '0 · the tool panel is hidden before any geometry is read (it is fixed OVER the device at 375)');

  const setVar = async v => { await p.evaluate(v => document.querySelector(`[data-var-set="${v}"]`).click(), v); };
  const reset = async () => { await p.evaluate(() => document.querySelector('[data-walk="reset"]').click()); };
  const create = async () => { await p.evaluate(() => document.querySelector('[data-walk="create"]').click()); await p.waitForTimeout(260); };
  const step = async k => { await p.evaluate(k => document.querySelector(`[data-walk="${k}"]`).click(), k); await p.waitForTimeout(160); };

  /* ---------- the measurement the round exists for ---------- */
  const probe = () => p.evaluate(() => {
    const g = NEW ? byId(NEW) : null;
    const row = g ? main.querySelector(`.row[data-id="${g.id}"]`) : null;
    const tabs = document.querySelector('.tabs').getBoundingClientRect();
    const fold = tabs.top;
    let geo = null;
    if (row) {
      const r = row.getBoundingClientRect();
      const hit = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
      geo = {
        top: +r.top.toFixed(1), bottom: +r.bottom.toFixed(1), h: +r.height.toFixed(1),
        visible: row.offsetParent !== null,
        aboveFold: r.top >= 0 && r.bottom <= fold,
        hitIsRow: !!(hit && (hit === row || row.contains(hit))),
        hitWas: hit ? (hit.className || hit.tagName) : null,
        fresh: row.classList.contains('fresh')
      };
    }
    /* how many places the new game can be reached from, on THIS rendering, without opening anything */
    const reach = g ? main.querySelectorAll(`.row[data-id="${g.id}"]`).length : 0;
    return {
      VAR: VAR, id: g && g.id, name: g && g.name, status: g && g.status, enr: g && g.enr,
      rowInDOM: !!row, geo, reach, fold: +fold.toFixed(1),
      nameInRenderedText: g ? main.innerText.includes(g.name) : false,
      captions: [...main.querySelectorAll('.lhead .ln')].map(e => e.textContent.trim()),
      draftCount: G.filter(x => x.status === 'draft').length,
      scrollTop: +scroller().scrollTop.toFixed(1),
      total: G.length
    };
  });

  const M = {};
  for (const v of VARS) {
    await reset(); await setVar(v);
    const before = await probe();
    await create();
    const after = await probe();
    M[v] = { before, after };
    await p.screenshot({ path: path.join(OUT, `076-${v}-created.png`) });
  }

  /* 1 — the incumbent defect, stated as DOM presence, not as geometry. This is the whole round's premise and
        it is asserted on V1 so it can never quietly stop being true. */
  ok(M.V1.after.rowInDOM === false && M.V1.after.nameInRenderedText === false,
    `1 · V1: the just-created game is NOT in the DOM and its name is nowhere in the rendered page ` +
    `(inDOM=${M.V1.after.rowInDOM}, nameInText=${M.V1.after.nameInRenderedText})`);

  /* 2 — and the ONLY thing that changed is a count inside a collapsed section */
  ok(M.V1.before.draftCount === 1 && M.V1.after.draftCount === 2 && M.V1.after.captions.length === 3,
    `2 · V1: Borradores ${M.V1.before.draftCount} -> ${M.V1.after.draftCount}, still ${M.V1.after.captions.length} captions — a counter is the entire feedback`);

  /* 3 — the created row matches the SHIPPED changeset, in every variant. If this drifts, the round is
        measuring an invented row. draft_changeset: name "Juego #<bgg_id>", status :draft, enrichment "pending". */
  for (const v of VARS) {
    const a = M[v].after;
    ok(a.name === 'Juego #342942' && a.status === 'draft' && a.enr === 'pending',
      `3${v} · the row the walk made is what draft_changeset writes: name="${a.name}" status=${a.status} enrichment=${a.enr}`);
  }

  /* 4 — one axis. `fresh` paint is identical in V2 and V3 and absent in V1, so a finding about WHERE cannot
        be blamed on HOW IT LOOKS. */
  ok(M.V2.after.geo.fresh === true && M.V3.after.geo.fresh === true,
    '4 · V2 and V3 paint the new row identically (.fresh in both) — the axis is position, not treatment');

  /* 5 — reachable at rest */
  for (const v of ['V2', 'V3']) {
    const g = M[v].after.geo;
    ok(g && g.visible && g.aboveFold,
      `5${v} · the new row is visible and above the fold at rest: y${g.top}-${g.bottom} vs fold ${M[v].after.fold}`);
  }

  /* 6 — THE HIT TEST. Visible + above the fold is not reachable: d17's sticky caption pins over the row.
        The first drawing of V2 passed check 5 and failed this one. */
  for (const v of ['V2', 'V3']) {
    const g = M[v].after.geo;
    ok(g && g.hitIsRow,
      `6${v} · elementFromPoint at the row's centre lands ON the row (got ${g && g.hitWas}) — a sticky caption cannot be covering it`);
  }

  /* 7 — NEGATIVE TEST for check 6. Strip the pinned-caption term from the scroll ceiling and V2 must fail,
        or check 6 is unfalsifiable. */
  await reset(); await setVar('V2');
  const broke = await p.evaluate(() => {
    const orig = window.scrollNewIntoView;
    window.scrollNewIntoView = function () {                 /* the version that only cleared --bar */
      const row = main.querySelector(`.row[data-id="${NEW}"]`); if (!row) return;
      const sc = scroller(), scTop = sc.getBoundingClientRect().top;
      const barPx = parseFloat(getComputedStyle(device).getPropertyValue('--bar')) || 0;
      sc.scrollTop += row.getBoundingClientRect().top - scTop - barPx - 8;
      updateBar();
    };
    document.querySelector('[data-walk="create"]').click();
    const row = main.querySelector(`.row[data-id="${NEW}"]`);
    const r = row.getBoundingClientRect();
    const hit = document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2);
    window.scrollNewIntoView = orig;
    return { hitIsRow: !!(hit && (hit === row || row.contains(hit))), hitWas: hit ? (hit.className || hit.tagName) : null };
  });
  ok(broke.hitIsRow === false,
    `7 · negative test: clearing only --bar puts the row under the pinned caption and check 6 FAILS (hit was "${broke.hitWas}") — the guard is falsifiable`);

  /* 8 — what the create does to the page under you. V2 scrolls; V3 does not move at all. */
  const travel = {};
  for (const v of VARS) travel[v] = +(M[v].after.scrollTop - M[v].before.scrollTop).toFixed(1);
  ok(travel.V1 === 0 && travel.V3 === 0 && travel.V2 > 0,
    `8 · page travel on create — V1 ${travel.V1}px · V2 ${travel.V2}px · V3 ${travel.V3}px (V3 delivers the row without moving the page)`);

  /* 9 — V3's duplication, and the charge had to be CORRECTED after measuring it.
        It was written expecting 2 at rest — the charge 074 laid against the duplicated back control and 075
        laid against V3/V4. Measured, V3 renders the row ONCE at rest, because `Borradores` is still collapsed
        and its rows are not in the DOM at all. The duplication is LATENT, not standing: it appears the moment
        the section is opened, which is one tap away.
        That makes it the fourth cost in this lineage that turned out to be a property of my own drawing rather
        than of the variant, so it is measured in both conditions instead of asserted in one. */
  const dup = await p.evaluate(() => {
    const out = {};
    for (const v of ['V1', 'V2', 'V3']) {
      document.querySelector('[data-walk="reset"]').click();
      document.querySelector(`[data-var-set="${v}"]`).click();
      document.querySelector('[data-walk="create"]').click();
      out[v] = { rest: main.querySelectorAll(`.row[data-id="${NEW}"]`).length };
      S.open.draft = true; render();
      out[v].opened = main.querySelectorAll(`.row[data-id="${NEW}"]`).length;
    }
    return out;
  });
  ok(dup.V1.rest === 0 && dup.V2.rest === 1 && dup.V3.rest === 1 &&
     dup.V1.opened === 1 && dup.V2.opened === 1 && dup.V3.opened === 2,
    `9 · rendered rows for the new game — at rest V1 ${dup.V1.rest} · V2 ${dup.V2.rest} · V3 ${dup.V3.rest}; ` +
    `with Borradores open V1 ${dup.V1.opened} · V2 ${dup.V2.opened} · V3 ${dup.V3.opened} ` +
    `(V3's duplication is LATENT — one tap away, not standing)`);

  /* 10 — and V3's other cost: a fourth caption on a page d17 made uniform */
  ok(M.V1.after.captions.length === 3 && M.V2.after.captions.length === 3 && M.V3.after.captions.length === 4,
    `10 · captions at rest — V1 ${M.V1.after.captions.length} · V2 ${M.V2.after.captions.length} · V3 ${M.V3.after.captions.length} (V3 adds "${M.V3.after.captions[0]}")`);

  /* 11 — d8's partition survives in all three: every game is in exactly one group, and the counts still add up.
         V3 renders the new row twice but must NOT change what the groups contain. */
  const part = await p.evaluate(() => {
    const seen = {}; let dup = 0;
    for (const g of G) { const ks = GROUPS.filter(x => x.has(g)).map(x => x.key); if (ks.length !== 1) dup++; seen[ks[0]] = (seen[ks[0]] || 0) + 1; }
    return { dup, seen, total: G.length, sum: Object.values(seen).reduce((a, b) => a + b, 0) };
  });
  ok(part.dup === 0 && part.sum === part.total,
    `11 · d8's partition intact: no game in two groups, ${JSON.stringify(part.seen)} = ${part.sum} of ${part.total}`);

  /* ---------- the walk continues: the job ends, and BOTH endings are reachable ---------- */
  /* 12 — 071 could only model success, on a 1600ms timer, so `failed` was unreachable and therefore untested.
         State is CARRIED: the row that changes is the one the walk created, not a fixture reload (075). */
  await reset(); await setVar('V2'); await create();
  const idBefore = await p.evaluate(() => NEW);
  await step('failed');
  const failed = await probe();
  ok(failed.id === idBefore && failed.enr === 'failed' && failed.name === 'Juego #342942',
    `12 · falló: the SAME row (id ${failed.id}) goes pending -> failed and the placeholder name SURVIVES ("${failed.name}") — nothing ever replaces it`);

  /* 13 — the failed row's second line is a dot + text (d19h/d40), never a pill or a badge */
  const failLine = await p.evaluate(() => {
    const row = main.querySelector(`.row[data-id="${NEW}"]`); if (!row) return null;
    const sub = row.querySelector('.sub'); const dot = sub && sub.querySelector('.dot');
    const cs = dot && getComputedStyle(dot);
    return {
      text: sub ? sub.innerText.trim() : null, hasDot: !!dot,
      dotBg: cs ? cs.backgroundColor : null,
      pill: sub ? /badge|pill|chip/.test(sub.className + ' ' + (sub.firstElementChild ? sub.firstElementChild.className : '')) : null
    };
  });
  ok(failLine && failLine.hasDot && failLine.pill === false && failLine.text.startsWith('Error'),
    `13 · the failed row is a dot + text, not a pill: "${failLine && failLine.text}"`);

  /* 14 — the dot is actually PAINTED. 075 found `.st.warn .dot` transparent for three whole sketches because
         it referenced a custom property the theme had renamed — invisible to every contrast assertion, since
         the element was present and its colour "correct". Asserted as a real alpha here for both states. */
  const dots = await p.evaluate(() => {
    const out = {};
    for (const k of ['pending', 'failed']) {
      const g = byId(NEW); g.enr = k; render();
      const d = main.querySelector(`.row[data-id="${NEW}"] .sub .dot`);
      out[k] = d ? getComputedStyle(d).backgroundColor : null;
    }
    return out;
  });
  const opaque = s => s && !/rgba\(0,\s*0,\s*0,\s*0\)/.test(s) && !/, 0\)$/.test(s);
  ok(opaque(dots.pending) && opaque(dots.failed),
    `14 · both status dots are really painted (pending ${dots.pending} · failed ${dots.failed}) — not an undefined custom property`);

  /* 15 — the success ending replaces the placeholder, and V3's block retires itself once resolved */
  await reset(); await setVar('V3'); await create();
  const v3Pending = await probe();
  await step('enriched');
  const v3Done = await probe();
  ok(v3Pending.captions.length === 4 && v3Done.captions.length === 3 && v3Done.name === 'Ark Nova' && v3Done.reach === 0,
    `15 · V3: once the data arrives the name becomes "${v3Done.name}" and "Recién agregado" retires (captions ${v3Pending.captions.length} -> ${v3Done.captions.length})`);

  /* 16 — ROUND 2: the unbuilt door is GONE, not disabled, in BOTH places that offered it. Round 1 kept it
         disabled to avoid silently reversing d4; the developer's call made it an explicit amendment instead,
         so the assertion flips from "present and disabled" to "absent".
         d4's other half must SURVIVE, or this becomes a bigger change than was asked for: the `+` still opens
         the sheet, the BGG field is still there, and the search still offers `Agregar desde BGG` for a pasted
         id. All four are asserted together so removing the manual path cannot quietly take the rest with it. */
  const door = await p.evaluate(() => {
    const r = {};
    document.querySelector('[data-act="add"]').click();
    r.sheetOpens = document.querySelector('#sheet').classList.contains('open');
    r.manual = !!document.querySelector('[data-act="manual"]');
    r.sep = !!document.querySelector('#sheet .fsep');
    r.bggField = !!document.querySelector('#bg');
    r.addBtn = !!document.querySelector('[data-act="addgo"]');
    r.hint = (document.querySelector('#sheet .hint') || {}).innerText || '';
    r.sheetH = Math.round(document.querySelector('#sheet').getBoundingClientRect().height);
    document.querySelector('[data-act="close"]').click();

    const q = document.querySelector('#q');
    q.value = 'un juego que no existe'; q.dispatchEvent(new Event('input', { bubbles: true }));
    r.searchCreate = !!document.querySelector('[data-act="create"]');
    r.searchEmpty = !!document.querySelector('#sugg .sgnone');
    q.value = '342942'; q.dispatchEvent(new Event('input', { bubbles: true }));
    r.searchAddBgg = !!document.querySelector('[data-act="addbgg"]');   /* d4's other answer must survive */
    q.value = ''; q.dispatchEvent(new Event('input', { bubbles: true }));
    return r;
  });
  ok(door.manual === false && door.sep === false && door.searchCreate === false &&
     door.sheetOpens && door.bggField && door.addBtn && door.searchAddBgg,
    `16 · the by-name path is gone from both doors (sheet ${door.manual}, separator ${door.sep}, search ${door.searchCreate}) ` +
    `and d4's rest survives (+ opens the sheet, BGG field, Agregar, and "Agregar desde BGG" for a pasted id)`);

  /* 16b — the hint no longer promises the one field enrichment never writes. `attrs_from_bgg_item/1` has no
          `weight_band`; only `admin_changeset` and the band-audit tool ever set the club's `nivel`. */
  ok(!/nivel/i.test(door.hint) && /tapa/.test(door.hint) && /borrador/.test(door.hint),
    `16b · the hint claims only what enrichment actually writes: "${door.hint.replace(/\n/g, ' ')}"`);

  /* 16c — what deleting the manual path bought, measured rather than asserted */
  ok(door.sheetH > 0, `16c · the sheet is now ${door.sheetH}px (it was 435px with the disabled manual path, of which 106px — 24% — was the unbuilt door)`);

  /* 17 — the new row clears the 44px touch floor, hit-tested rather than read off a rect */
  await reset(); await setVar('V2'); await create();
  const touch = await p.evaluate(() => {
    const row = main.querySelector(`.row[data-id="${NEW}"]`); const r = row.getBoundingClientRect();
    const pts = [[r.left + 24, r.top + 6], [r.left + r.width / 2, r.bottom - 6]];
    return { h: +r.height.toFixed(1), all: pts.every(([x, y]) => { const e = document.elementFromPoint(x, y); return !!(e && (e === row || row.contains(e))); }) };
  });
  ok(touch.h >= 44 && touch.all, `17 · the new row is ${touch.h}px and every probe inside it lands on the row`);

  /* 18 — V1 IS 071, proven rather than asserted. The whole round rests on "the incumbent shows you nothing",
         so the incumbent had better be the incumbent.
         Compared as RENDERED DOM, not as pixels. A pixel diff was tried first and measured the wrong thing
         twice: the first version came back 218,063px because 071 still carried `device kbd` (openSheet focuses
         its input on a 60ms timer that lands AFTER a synchronous closeSheet, so the simulated keyboard
         reappears on a closed sheet); the second still came back 203,651px because the sheet's focus call
         scrolls the DOCUMENT and a screenshot `clip` is in page coordinates, so each page was captured from a
         different origin. Both were facts about the harness. The list's markup is what the claim is actually
         about, and it has neither failure mode.
         The new row's id differs by construction (071 and 076 mint from different array lengths), so ids are
         normalised out; nothing else is. */
  const listHTML = async (url, pickV1) => {
    const q = await ctx.newPage();
    await q.goto(url, { waitUntil: 'networkidle' });
    await q.evaluate(pick => {
      if (pick) document.querySelector('[data-var-set="V1"]').click();
      document.querySelector('[data-act="add"]').click();
      const f = document.querySelector('#bg'); f.value = '342942';
      f.dispatchEvent(new Event('input', { bubbles: true }));
      document.querySelector('[data-act="addgo"]').click();
    }, pickV1);
    await q.waitForTimeout(220);                       /* before 071's 1600ms rename timer fires */
    const html = await q.evaluate(() =>
      [...main.querySelectorAll('.lgroup')].map(s => s.outerHTML).join('\n')
        .replace(/data-id="\d+"/g, 'data-id="#"'));
    await q.close(); return html;
  };
  const h071 = await listHTML(URL.replace('076-admin-create-visibility', '071-admin-juegos'), false);
  const h076 = await listHTML(URL, true);
  let firstDiff = -1;
  for (let i = 0; i < Math.max(h071.length, h076.length); i++) if (h071[i] !== h076[i]) { firstDiff = i; break; }
  ok(h071 === h076,
    `18 · V1 renders the same list DOM as 071 at the create moment (${h076.length} chars` +
    (firstDiff < 0 ? ', identical' : `, first difference at ${firstDiff}: "${h071.slice(firstDiff, firstDiff + 60)}" vs "${h076.slice(firstDiff, firstDiff + 60)}"`) +
    ') — the baseline really is the incumbent');

  /* 19 — a failed game has no cover, in every variant. Found in a screenshot of the `falló` step: the row was
         rendering the decorative coloured initial (a green "J") next to "Error al traer datos de BGG", because
         071's fall-through only reaches `.none` for `gap` games and the new game is not one. Negative-tested
         below by restoring the old predicate. */
  const cov = await p.evaluate(() => {
    document.querySelector('[data-walk="reset"]').click();
    document.querySelector('[data-var-set="V3"]').click();
    document.querySelector('[data-walk="create"]').click();
    document.querySelector('[data-walk="failed"]').click();
    const c = main.querySelector(`.row[data-id="${NEW}"] .cov`);
    const before = c ? c.className : null;
    const orig = window.noCover; window.noCover = () => false; render();   /* 071's predicate */
    const c2 = main.querySelector(`.row[data-id="${NEW}"] .cov`);
    const after = c2 ? c2.className : null;
    window.noCover = orig; render();
    return { fixed: before, unfixed: after };
  });
  ok(/\bnone\b/.test(cov.fixed) && /\bl\b/.test(cov.unfixed),
    `19 · a failed game gets the no-cover glyph, not a decorative initial ("${cov.fixed}"); reverting the predicate brings the initial back ("${cov.unfixed}") — negative-tested`);

  /* 20 — V3's third cost, found in the same screenshot: the failure is announced TWICE. d24 put "N con error"
         on a collapsed caption precisely because "a failure inside a CLOSED section is otherwise invisible" —
         but in V3 it is not invisible, it is the row directly above. V2 does not pay this: its section is open,
         so d24's caption warning is suppressed by its own rule. */
  const twice = await p.evaluate(() => {
    const out = {};
    for (const v of ['V1', 'V2', 'V3']) {
      document.querySelector('[data-walk="reset"]').click();
      document.querySelector(`[data-var-set="${v}"]`).click();
      document.querySelector('[data-walk="create"]').click();
      document.querySelector('[data-walk="failed"]').click();
      const rows = main.querySelectorAll(`.row[data-id="${NEW}"] .sub .dot.err`).length;
      const caps = main.querySelectorAll('.lhead .warn').length;
      out[v] = { rows, caps, total: rows + caps };
    }
    return out;
  });
  ok(twice.V1.total === 1 && twice.V2.total === 1 && twice.V3.total === 2,
    `20 · how many times "this one failed" is said at rest — V1 ${twice.V1.rows}+${twice.V1.caps}=${twice.V1.total} · ` +
    `V2 ${twice.V2.rows}+${twice.V2.caps}=${twice.V2.total} · V3 ${twice.V3.rows}+${twice.V3.caps}=${twice.V3.total} ` +
    `(V3 shows the failed row AND d24's caption warning for the same game)`);

  /* 21 — nothing in the page threw while all of the above ran */
  ok(errs.length === 0, `21 · no page errors (${errs.length ? errs.join(' | ') : 'none'})`);

  /* ---------- the comparison table the round is decided on ---------- */
  console.log('\n  ' + ['', 'en pantalla', 'y=', 'toques', 'viaje', 'duplicado', 'rótulos'].join('\t'));
  for (const v of VARS) {
    const a = M[v].after, g = a.geo;
    console.log('  ' + [v,
      g && g.visible && g.aboveFold && g.hitIsRow ? 'sí' : 'NO',
      g ? `${Math.round(g.top)}-${Math.round(g.bottom)}` : '—',
      a.rowInDOM ? '0' : '1 (abrir la sección)',
      travel[v] + 'px', a.reach, a.captions.length].join('\t'));
  }

  console.log('\n' + log.join('\n'));
  const pass = log.filter(l => l.startsWith('PASS')).length;
  console.log(`\n${pass}/${log.length}`);
  console.log('shots: ' + OUT);
  await browser.close();
  process.exit(pass === log.length ? 0 : 1);
})();
