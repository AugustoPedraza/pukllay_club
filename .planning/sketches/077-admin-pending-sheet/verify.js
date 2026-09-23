/* Headless-Chrome checks for sketch 077 — slice 2 of the create -> edit -> draft -> failed scenario.
   Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/077-admin-pending-sheet/verify.js
   Env: PLAYWRIGHT_CORE, SKETCH_URL, SHOTS_DIR (default <os tmp>/sketch-077-shots).

   THE ROUND'S QUESTION: you tap a pending row, a sheet opens and says it is working — WHO SPEAKS when the
   data lands? AV1 sólo la hoja · AV2 los dos (the do-nothing baseline) · AV3 se retira.

   Traps this file is written around. The first two are NEW to this round; the rest are inherited from 076
   and 075, where each one produced a green number that described something other than the page.

     · `#snack` CARRYING THE CLASS `show` DOES NOT TELL YOU WHICH SNACK IT IS. The create snackbar
       ("Juego agregado como borrador") lives 4000ms, and a walk that steps create -> tap -> arrival takes
       about 1300ms, so the create snack is STILL UP when the completion toast is being asked about. The
       first measurement taken while building this sketch reported the toast firing under AV1 — which is
       exactly what AV1 suppresses — because it read the class and not the text. Every toast assertion below
       reads `#snack span` TEXT and matches it against the completion wording.
     · CLICKING A WALK BUTTON THROUGH PLAYWRIGHT'S `click()` FAILS WHILE `#tools` IS HIDDEN, because the
       control being clicked is inside the panel. Hiding the panel and then driving it is self-contradictory.
       Every step below is dispatched with `el.click()` inside `evaluate`, and the panel is hidden only
       around screenshots and geometry.
     · A top-level `const`/`let` in a classic script is a LEXICAL BINDING, not a property of `window`, so a
       harness assignment changes nothing while appearing to (076, twice). `opensSheet` is a function
       DECLARATION reached through `window`, so check 4 can actually falsify check 3.
     · The tool panel is `position: fixed` OVER the device at 375px and swallows `elementFromPoint` probes.
       Check 0 asserts it is really hidden before any hit test.
     · "On screen" is NOT `rect.bottom <= scroller.bottom`. The 67px tab bar OVERLAYS the scroller (075), so
       the scroller reports 740 while the eye stops at 673. The fold is `.tabs`'s top.
     · Visible + above the fold is NOT reachable — d17's sticky captions pin over a row a scroll just
       delivered (076's V2, y121-185, every ordinary check green, `elementFromPoint` returning `.lhead`).
       Only a hit test sees it. */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();
const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/077-admin-pending-sheet/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-077-shots'); fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);

const AVS = ['AV1', 'AV2', 'AV3'];
const step = (p, k) => p.evaluate(k => document.querySelector(`[data-walk="${k}"]`).click(), k);
const setAV = (p, v) => p.evaluate(v => document.querySelector(`[data-av-set="${v}"]`).click(), v);
const hideTools = p => p.evaluate(() => document.getElementById('tools').style.visibility = 'hidden');
const showTools = p => p.evaluate(() => document.getElementById('tools').style.visibility = '');
const snackText = p => p.evaluate(() => {
  const s = document.getElementById('snack');
  return s.classList.contains('show') ? s.querySelector('span').textContent.trim() : null;
});
/* Clearing the snackbar immediately BEFORE the arrival step is what makes every toast assertion below
   unambiguous: whatever is on screen afterwards can only have come from the arrival. The alternative —
   waiting out the create snackbar's 4000ms — is both slower and still wrong the moment a previous
   variant's 10000ms completion toast is the thing still up. */
const clearSnack = p => p.evaluate(() => document.getElementById('snack').classList.remove('show'));
const sheetState = p => p.evaluate(() => {
  const sh = document.getElementById('sheet');
  if (!sh.classList.contains('open')) return { open: false };
  const r = sh.getBoundingClientRect();
  return {
    open: true, top: Math.round(r.top), height: Math.round(r.height),
    title: sh.querySelector('.sh-title')?.textContent.trim() || '',
    ctx: sh.querySelector('.ctx')?.textContent.trim() || '',
    btn: sh.querySelector('.obtn')?.textContent.trim() || null,
    html: sh.innerHTML
  };
});

(async () => {
  const browser = await chromium.launch({ channel: 'chrome', headless: true });
  const errs = [];
  const ctx = await browser.newContext({ viewport: { width: 375, height: 740 }, deviceScaleFactor: 2 });
  const page = await ctx.newPage();
  page.on('pageerror', e => errs.push(String(e)));
  /* a bare "Failed to load resource" console error names nothing, so the URL is captured alongside it —
     otherwise check 31 reports a 404 the reader cannot act on. */
  page.on('response', r => { if (r.status() >= 400) errs.push(`HTTP ${r.status()} ${r.url()}`); });
  page.on('requestfailed', r => errs.push(`REQFAIL ${r.url()} ${r.failure()?.errorText || ''}`));
  page.on('console', m => { if (m.type() === 'error') errs.push('console: ' + m.text()); });
  await page.goto(URL, { waitUntil: 'networkidle' });

  /* ---- 0. the panel really is out of the way before any geometry or hit test ---- */
  await hideTools(page);
  ok(await page.evaluate(() => getComputedStyle(document.getElementById('tools')).visibility === 'hidden'),
    '0  the tool panel is hidden before any hit test (it is fixed OVER the device at 375px)');
  await showTools(page);

  /* ================= the row, and D-19i ================= */
  await step(page, 'create'); await page.waitForTimeout(350);

  const rows = await page.evaluate(() => {
    const all = [...document.querySelectorAll('#main .row')];
    return {
      total: all.length,
      withChev: all.filter(r => r.querySelector('.chev')).length,
      pending: all.filter(r => r.dataset.act === 'pending').length,
      pendingHasChev: all.filter(r => r.dataset.act === 'pending' && r.querySelector('.chev')).length,
      pendingInDom: all.some(r => r.dataset.act === 'pending'),
      pendingVisible: all.filter(r => r.dataset.act === 'pending').every(r => r.offsetParent !== null)
    };
  });
  ok(rows.pendingInDom && rows.pendingVisible,
    '1  the pending row is in the DOM and rendered (076: absence reads as "not visible" through every geometry check without saying so)');
  ok(rows.pending === 1 && rows.pendingHasChev === 0,
    `2  the pending row opens a sheet (data-act="pending") — ${rows.pending} row`);
  ok(rows.withChev === rows.total - 1,
    `3  D-19i: the pending row is the ONLY game row without a chevron — ${rows.withChev} of ${rows.total} keep one`);

  /* 4 — the negative test, through a function DECLARATION so it can actually bite */
  await page.evaluate(() => { window.opensSheet = () => false; render(); });
  const restored = await page.evaluate(() => {
    const all = [...document.querySelectorAll('#main .row')];
    return { withChev: all.filter(r => r.querySelector('.chev')).length, total: all.length };
  });
  ok(restored.withChev === restored.total,
    `4  NEGATIVE TEST — restore 076's predicate and check 3 goes red: every row wears a chevron again (${restored.withChev}/${restored.total})`);
  await page.evaluate(() => { window.opensSheet = g => (g.enr || 'enriched') === 'pending'; render(); });

  /* ---- 5. the row is REACHABLE by a real tap, not merely visible (076's V2 trap) ---- */
  await hideTools(page);
  const hit = await page.evaluate(() => {
    const r = document.querySelector('#main .row[data-act="pending"]').getBoundingClientRect();
    const el = document.elementFromPoint(Math.round(r.left + r.width / 2), Math.round(r.top + r.height / 2));
    const row = el && el.closest('[data-act]');
    return { act: row ? row.dataset.act : null, label: el ? (el.className || el.tagName) : null };
  });
  ok(hit.act === 'pending',
    `5  a tap at the pending row's centre actually lands on it (d17's captions are sticky) — got ${hit.act || hit.label}`);
  await showTools(page);

  /* ================= the wait ================= */
  await step(page, 'sheet'); await page.waitForTimeout(400);
  await hideTools(page);
  const waiting = await sheetState(page);
  await page.screenshot({ path: OUT + '/waiting.png' });
  await showTools(page);

  ok(waiting.open && /Trayendo/.test(waiting.title),
    `6  tapping the pending row opens the sheet, waiting state — "${waiting.title}"`);
  ok(waiting.ctx === 'BGG 342942',
    `7  the sheet names WHICH game by the id you typed — "${waiting.ctx}"`);
  ok(waiting.btn === null,
    '8  the waiting state offers no action — there is nothing to do but wait');

  /* 9 — THE ROUND'S OWN COST, counted rather than waved through: the row and the sheet say the same
     sentence, at the same time, 500px apart. d24 already put it on the row; the shipped app says
     "Juego #<bgg_id> (cargando…)" at index.ex:241. */
  const says = await page.evaluate(() => {
    const t = s => (document.body.innerText.match(new RegExp(s, 'g')) || []).length;
    return { trayendo: t('Trayendo datos de BGG') };
  });
  ok(says.trayendo === 2,
    `9  COUNTED, not fixed: the page says "Trayendo datos de BGG" ${says.trayendo}x at once — the row (d24) and the sheet's own title`);

  /* 10 — does the sheet cover the row it is about? */
  const cover = await page.evaluate(() => {
    const row = document.querySelector('#main .row[data-act="pending"]');
    if (!row) return { gone: true };
    const r = row.getBoundingClientRect(), sh = document.getElementById('sheet').getBoundingClientRect();
    return { gone: false, rowBottom: Math.round(r.bottom), sheetTop: Math.round(sh.top), clear: r.bottom <= sh.top };
  });
  ok(cover.clear,
    `10 the sheet does not cover the row it is about — row ends y${cover.rowBottom}, sheet starts y${cover.sheetTop}`);

  /* ---- 11. the sheet's CONTENT is identical across the three variants, so nothing found at the arrival
       can be blamed on treatment rather than on the axis ---- */
  const waitHtml = {};
  for (const v of AVS) { await setAV(page, v); await page.waitForTimeout(120); waitHtml[v] = (await sheetState(page)).html; }
  ok(waitHtml.AV1 === waitHtml.AV2 && waitHtml.AV2 === waitHtml.AV3,
    '11 the waiting sheet is byte-identical in AV1/AV2/AV3 — the axis is the arrival only');

  /* ================= THE ARRIVAL — the round's axis ================= */
  const arrival = {};
  for (const v of AVS) {
    await step(page, 'reset'); await page.waitForTimeout(150);
    await setAV(page, v); await page.waitForTimeout(80);
    await step(page, 'create'); await page.waitForTimeout(250);
    await step(page, 'sheet'); await page.waitForTimeout(300);
    await clearSnack(page);
    ok(await snackText(page) === null, `12${v} precondition — nothing on the snackbar before the arrival, so what appears after it can only be the arrival's`);
    await step(page, 'enriched'); await page.waitForTimeout(350);
    await hideTools(page);
    arrival[v] = { sheet: await sheetState(page), snack: await snackText(page) };
    await page.screenshot({ path: OUT + `/arrival-${v}.png` });
    await showTools(page);
  }

  const a1 = arrival.AV1, a2 = arrival.AV2, a3 = arrival.AV3;
  const isToast = s => !!s && /ya tiene sus datos|No pudimos traer/.test(s);

  ok(a1.sheet.open && a1.sheet.title === 'Ark Nova agregado' && a1.sheet.btn === 'Ver',
    `13 AV1 — the sheet transforms in place: "${a1.sheet.title}" + [${a1.sheet.btn}]`);
  ok(!isToast(a1.snack),
    `14 AV1 — the toast is suppressed for the game whose sheet is open (check 25's rule, one more container) — snack: ${a1.snack === null ? 'none' : '"' + a1.snack + '"'}`);

  ok(a2.sheet.open && a2.sheet.title === 'Ark Nova agregado',
    '15 AV2 — the sheet transforms too');
  ok(isToast(a2.snack),
    `16 AV2 is THE DO-NOTHING BASELINE and it is what makes check 14 falsifiable: with no suppression the toast fires over the open sheet — "${a2.snack}"`);

  ok(!a3.sheet.open,
    '17 AV3 — the sheet retires on arrival');
  ok(isToast(a3.snack),
    `18 AV3 — the toast is the announcement — "${a3.snack}"`);

  /* 19 — the collision AV2 pays for, said as a number */
  ok(a2.sheet.open && isToast(a2.snack) && a1.sheet.open && !isToast(a1.snack),
    '19 the axis is real: at the same moment AV2 announces twice and AV1 once');

  /* 19b/19c — FOUND IN THE SCREENSHOT, AGAINST A GREEN CHECK. Check 16 passed: under AV2 the completion
     toast fires and its text is the completion wording. The shot of that exact moment does not contain it.
     `.snack` is z-index 30; `.backdrop` is 40 and `.sheet` is 41, and the snack's `bottom: 79px` puts it
     inside the sheet's own area — so the second announcement is emitted, is covered by the sheet and dimmed
     by the scrim, and BURNS ITS 10000ms UNSEEN. Dismiss the sheet at second 11 and it was never there.
     That is the eleventh time in this lineage a green number described something other than the page.

     NOT OVERCLAIMED: the z-order is inherited from 076, not chosen for this round, and raising the toast
     above the sheet is a one-line change. Both readings are recorded in the README, because AV2 loses under
     either — as built the announcement is swallowed; raised, it is two announcements about one game stacked
     on each other, which is the thing check 25's rule exists to prevent. */
  await step(page, 'reset'); await page.waitForTimeout(150);
  await setAV(page, 'AV2'); await step(page, 'create'); await page.waitForTimeout(250);
  await step(page, 'sheet'); await page.waitForTimeout(300); await clearSnack(page);
  await step(page, 'enriched'); await page.waitForTimeout(350);
  await hideTools(page);
  const buried = await page.evaluate(() => {
    const sn = document.getElementById('snack'), sh = document.getElementById('sheet');
    const r = sn.getBoundingClientRect();
    const el = document.elementFromPoint(Math.round(r.left + r.width / 2), Math.round(r.top + r.height / 2));
    return {
      shown: sn.classList.contains('show'),
      z: { snack: getComputedStyle(sn).zIndex, backdrop: getComputedStyle(document.getElementById('backdrop')).zIndex, sheet: getComputedStyle(sh).zIndex },
      hitsSnack: !!(el && el.closest('#snack')),
      hits: el ? (el.id || el.className || el.tagName) : null
    };
  });
  await showTools(page);
  ok(buried.shown && !buried.hitsSnack,
    `19b the toast AV2 fires is BURIED: it carries .show, and a probe at its own centre returns "${buried.hits}" instead`);
  ok(Number(buried.z.snack) < Number(buried.z.sheet),
    `19c the cause, in numbers: .snack z-index ${buried.z.snack} vs .backdrop ${buried.z.backdrop} vs .sheet ${buried.z.sheet}`);

  /* 20 — "agregado", counted across the whole walk. The create snackbar already said it once. */
  await step(page, 'reset'); await page.waitForTimeout(150);
  await setAV(page, 'AV1'); await step(page, 'create'); await page.waitForTimeout(250);
  const createSnack = await snackText(page);
  await step(page, 'sheet'); await page.waitForTimeout(300);
  await clearSnack(page);
  await step(page, 'enriched'); await page.waitForTimeout(300);
  const arrivedTitle = (await sheetState(page)).title;
  const agregadoCount = [createSnack, arrivedTitle].filter(t => t && /agregad/.test(t)).length;
  ok(agregadoCount === 2,
    `20 COUNTED, not fixed: "agregad*" is said ${agregadoCount}x about one game — "${createSnack}" at create, "${arrivedTitle}" at arrival`);

  /* 21 — the arrived body claims nothing about WHICH fields came back (d51/d53 obeyed, not rediscovered) */
  const body = await page.evaluate(() => document.querySelector('#sheet .pbody')?.innerText.trim() || '');
  ok(!/tapa|jugador|duraci|nivel|descripci/i.test(body + ' ' + arrivedTitle),
    '21 the arrived sheet enumerates no fields — d51 had to delete `y el nivel` from exactly such a list once enrichment turned out never to write weight_band, and d53 deleted the list outright');

  /* 22 — `Ver` is a real target and goes to THAT game */
  await hideTools(page);
  const ver = await page.evaluate(() => {
    const b = document.querySelector('#sheet .obtn'); const r = b.getBoundingClientRect();
    const el = document.elementFromPoint(Math.round(r.left + r.width / 2), Math.round(r.top + r.height / 2));
    return { h: Math.round(r.height), hits: el && el.closest('[data-act]')?.dataset.act === 'sheetgo', id: b.dataset.id };
  });
  ok(ver.h >= 44 && ver.hits, `22 «Ver» is a ${ver.h}px hit-tested target`);
  await showTools(page);
  await page.evaluate(() => document.querySelector('#sheet .obtn').click());
  await page.waitForTimeout(300);
  const after = await page.evaluate(() => ({
    screen: S.screen, editing: S.editing,
    sheetOpen: document.getElementById('sheet').classList.contains('open'),
    sheetFor: S.sheetFor
  }));
  ok(after.screen === 'editor' && String(after.editing) === String(ver.id),
    '23 «Ver» opens the editor for THAT game');
  ok(!after.sheetOpen && after.sheetFor === null,
    '24 the sheet closes before navigating — a status about the game never sits on top of the game');

  /* 25 — d55's own rule, still standing: no completion toast for a game whose editor you are reading */
  await step(page, 'reset'); await page.waitForTimeout(150);
  await setAV(page, 'AV2'); await page.waitForTimeout(80);   /* AV2, so nothing but the editor rule can suppress it */
  await step(page, 'create'); await page.waitForTimeout(250);
  await page.evaluate(() => openGame(NEW, 'juegos'));
  await page.waitForTimeout(200); await clearSnack(page);
  await step(page, 'enriched'); await page.waitForTimeout(300);
  ok(!isToast(await snackText(page)),
    '25 d55 UPHELD: no completion toast for a game whose editor is already open, even under AV2');

  /* ================= the failure branch (minimal — designing it is slice 079) ================= */
  await step(page, 'reset'); await page.waitForTimeout(150);
  await setAV(page, 'AV1'); await step(page, 'create'); await page.waitForTimeout(250);
  await step(page, 'sheet'); await page.waitForTimeout(300);
  await clearSnack(page);
  await step(page, 'failed'); await page.waitForTimeout(350);
  await hideTools(page);
  const failed = await sheetState(page);
  await page.screenshot({ path: OUT + '/arrival-failed.png' });
  await showTools(page);
  ok(failed.open && /No pudimos/.test(failed.title) && failed.btn === 'Ver',
    `26 a sheet open when the job DIES still says something — "${failed.title}" + [${failed.btn}]`);
  ok(/Juego #342942/.test(failed.html),
    '27 on failure the name is still the placeholder — nothing ever replaces it (enrichment.ex:144)');
  ok(/quedó agregado igual/.test(failed.html),
    '28 the failure sheet says the load-bearing thing: the game still exists as a draft');

  /* ================= reset ================= */
  await step(page, 'reset'); await page.waitForTimeout(250);
  const reset = await page.evaluate(() => ({
    sheetOpen: document.getElementById('sheet').classList.contains('open'),
    sheetFor: S.sheetFor, screen: S.screen, isNew: NEW
  }));
  ok(!reset.sheetOpen && reset.sheetFor === null && reset.screen === 'juegos' && reset.isNew === null,
    '29 ↺ closes the sheet as well as leaving the editor — no sheet describing a game that is gone');

  /* ================= both themes ================= */
  for (const th of ['light', 'dark']) {
    await page.evaluate(t => document.querySelector(`[data-theme-set="${t}"]`).click(), th);
    await step(page, 'create'); await page.waitForTimeout(200);
    await step(page, 'sheet'); await page.waitForTimeout(350);
    await hideTools(page);
    await page.screenshot({ path: OUT + `/waiting-${th}.png` });
    const vis = await page.evaluate(() => {
      const t = document.querySelector('#sheet .sh-title'), p = document.querySelector('#sheet .pwait p');
      const sp = document.querySelector('#sheet .spin');
      return { title: getComputedStyle(t).color, prose: getComputedStyle(p).color, spin: !!sp && sp.offsetParent !== null };
    });
    await showTools(page);
    ok(vis.spin, `30${th} the spinner renders in ${th}`);
    await step(page, 'reset'); await page.waitForTimeout(150);
  }
  await page.evaluate(() => document.querySelector('[data-theme-set="light"]').click());

  /* ---- 32 — PERSISTENCE, which is the real difference between AV1 and AV3 and is invisible at t=0 ----
     Both announce. Only one of them is still there a moment later. `snack()` clears itself after 10000ms
     (076 raised it from 4000 for the actioned form); the sheet has no timer at all and waits to be
     dismissed. 076's own open list already flagged this about the toast — *"a missed toast has no second
     chance"* — and here it is measured rather than asserted. Worth the 21s it costs: it is the round's
     central comparison, and a structural claim about `setTimeout` would not prove what is ON SCREEN. */
  const survives = {};
  for (const v of ['AV1', 'AV3']) {
    await step(page, 'reset'); await page.waitForTimeout(150);
    await setAV(page, v); await step(page, 'create'); await page.waitForTimeout(250);
    await step(page, 'sheet'); await page.waitForTimeout(300); await clearSnack(page);
    await step(page, 'enriched'); await page.waitForTimeout(10400);   /* past snack()'s 10000ms life */
    await hideTools(page);
    survives[v] = await page.evaluate(() => {
      const sh = document.getElementById('sheet');
      const sheetSays = sh.classList.contains('open') ? (sh.querySelector('.sh-title')?.textContent.trim() || '') : '';
      const sn = document.getElementById('snack');
      const snackSays = sn.classList.contains('show') ? sn.querySelector('span').textContent.trim() : '';
      return { sheetSays, snackSays, anySays: /Ark Nova/.test(sheetSays + snackSays) };
    });
    await page.screenshot({ path: OUT + `/after-10s-${v}.png` });
    await showTools(page);
  }
  ok(survives.AV1.anySays,
    `32 AV1 — ten seconds later the announcement is still on screen: "${survives.AV1.sheetSays}" (a sheet has no timer; it waits to be dismissed)`);
  ok(!survives.AV3.anySays,
    '33 AV3 — ten seconds later NOTHING on screen says the data arrived. The sheet retired and snack() cleared itself; the row is the only durable record, which is 076 round 1\'s question returning intact');

  ok(errs.length === 0, `31 no page errors${errs.length ? ' — ' + errs.join(' | ') : ''}`);

  console.log(log.join('\n'));
  const pass = log.filter(l => l.startsWith('PASS')).length;
  console.log(`\n${pass}/${log.length}`);
  console.log('shots: ' + OUT);
  await browser.close();
  process.exit(pass === log.length ? 0 : 1);
})();
