/* Headless-Chrome checks for sketch 078 — slice 3 of the create scenario: the draft, the publish gate,
   and the lifecycle. Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/078-admin-publish-gate/verify.js
   Env: PLAYWRIGHT_CORE, SKETCH_URL, SHOTS_DIR (default <os tmp>/sketch-078-shots).

   THE ROUND'S QUESTION: the draft is incomplete and you reach for Publicar. WHO STOPS YOU, AND HOW?
   G1 bloquea · G2 avisa · G3 la ficha (the do-nothing baseline).

   WHAT THE GATE REQUIRES IS MEASURED, NOT VARIED — and checks 7/9/11 are where that measurement is made
   falsifiable rather than asserted in prose:
     · copias is NOT a gate item in any variant, and the row pre-fills 1   (434/434 published = 1)
     · estante is NOT a gate item in any variant                          (433/434 published have none)
     · nivel IS a gate item, and it VANISHES for an expansion              (408/408 base · 0/26 expansions)

   Traps this file is written around — the first is new to this round, the rest inherited from 075-077,
   where each one produced a green number that described something other than the page.

     · A GATE CHECK THAT READS ONLY `#publish[disabled]` CANNOT DISTINGUISH G2 FROM G3. Both render a live
       button; they diverge only at the TAP. Every G2/G3 assertion below therefore DRIVES the tap and reads
       what came back (a dialog, or a published game) rather than reading the resting page.
     · A DISABLED BUTTON DOES NOT PROVE A GATE. `#publish[disabled]` is also what you get if the walk never
       reached the editor. Check 2 asserts the button EXISTS and is enabled in the complete case before
       check 3 is allowed to mean anything, and check 12 negative-tests the gate by emptying `missing()`.
     · CLICKING A WALK BUTTON THROUGH PLAYWRIGHT'S `click()` FAILS WHILE `#tools` IS HIDDEN. Every step is
       dispatched with `el.click()` inside `evaluate`; the panel is hidden only around screenshots.
     · A top-level `const`/`let` in a classic script is a LEXICAL BINDING, not a property of `window`, so a
       harness assignment changes nothing while appearing to (076, twice; 077 once). `missing` is a function
       DECLARATION reached through `window`, so check 12 can actually falsify checks 3 and 6.
     · The tool panel is `position: fixed` OVER the device and swallows `elementFromPoint`. Check 0 asserts
       it is really hidden before any hit test.
     · `#snack` carrying `.show` does not tell you WHICH snack it is (077). Every snack assertion reads
       `#snack span` text. */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();
const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/078-admin-publish-gate/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-078-shots'); fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);

const GATES = ['G1', 'G2', 'G3'];
const step = (p, k) => p.evaluate(k => document.querySelector(`[data-walk="${k}"]`).click(), k);
const setGate = (p, v) => p.evaluate(v => document.querySelector(`[data-g-set="${v}"]`).click(), v);
const setMode = (p, v) => p.evaluate(v => document.querySelector(`[data-m-set="${v}"]`).click(), v);
const setTool = (p, attr, v) => p.evaluate(([a, v]) => document.querySelector(`[data-${a}-set="${v}"]`).click(), [attr, v]);
const hideTools = p => p.evaluate(() => document.getElementById('tools').style.visibility = 'hidden');
const showTools = p => p.evaluate(() => document.getElementById('tools').style.visibility = '');
const reset = p => step(p, 'reset');

/* the walk, to the editor of an enriched, incomplete draft. Every check that needs that state calls this
   rather than repeating the steps, so a change to the walk cannot leave half the checks measuring a
   different page from the other half. */
/* ROUND 1'S CHECKS RUN IN MODE B, AND THAT IS ITSELF A ROUND-2 FINDING.
   Round 1 asks how the gate SPEAKS, which presupposes somewhere to speak. 074's top bar is `‹ · título ·
   CTA` and has no slot for a sentence — so G1's explanation is only buildable in B. Pinning the round-1
   checks to B keeps them measuring what they were written to measure; check 22 is where the dependency
   itself is asserted instead of being hidden by this convenience. */
async function toEditor(p, mode = 'B') {
  await reset(p);
  await setMode(p, mode);
  await step(p, 'create'); await step(p, 'enriched'); await step(p, 'edit');
  /* THE SNACKBAR IS CLEARED HERE ON PURPOSE, AND CHECK 16 IS WHY IT IS NOT SWEPT UNDER THE RUG.
     d55's completion toast lives 10000ms and the walk reaches the editor about a second after it fires, so
     every check below would otherwise be measuring the gate THROUGH a toast that covers it — and check 11
     would be driving a button no finger could reach. Check 16 walks WITHOUT this line and asserts the
     collision, so the cost is counted rather than hidden by the convenience that makes the rest legible. */
  await clearSnack(p);
  /* the snackbar fades out over a transition; a screenshot taken immediately catches its GHOST superimposed
     on the bar, which is how the first clean-looking capture of this round still showed two overlapping
     sentences. Waiting out the transition is part of clearing it. */
  await p.waitForTimeout(260);
}
/* 077's lesson, reused: whatever is on screen after this can only have come from what happened next. */
const clearSnack = p => p.evaluate(() => document.getElementById('snack').classList.remove('show'));
/* the REAL button, not the walk's shortcut. `step(p,'publish')` calls doPublish() directly, which is how
   11d found that G1's gate lived only in the paint — but it also bypasses anything COVERING the button, so
   a check that only ever used it could not see check 16's collision. Both routes are used deliberately. */
const tapPublish = p => p.evaluate(() => { const b = document.getElementById('publish'); b && b.click(); });

const gateState = p => p.evaluate(() => {
  const b = document.getElementById('publish');
  const why = document.querySelector('#tbar .why, #stack .why, #savebar .why');
  const g = window.byId(window.S.editing);
  return {
    hasBtn: !!b,
    disabled: b ? b.disabled : null,
    why: why ? why.textContent.trim() : '',
    missing: g ? window.missing(g).map(m => m.k) : null,
    status: g ? g.status : null,
    units: g ? g.units : null,
    unitsRow: (document.querySelector('[data-field="units"] .fr-v') || {}).textContent || '',
    missDots: document.querySelectorAll('.frow .miss').length,
    missDotKeys: [...document.querySelectorAll('.frow')].filter(r => r.querySelector('.miss')).map(r => r.dataset.field),
    dialogOpen: document.getElementById('dscrim').classList.contains('open'),
    dialogText: document.getElementById('dlg-d').textContent.trim(),
    snack: document.getElementById('snack').classList.contains('show')
      ? document.getElementById('snack').querySelector('span').textContent.trim() : null
  };
});

(async () => {
  /* no ms-playwright browser is cached on this machine; the system Chrome is used instead. Kept as an env
     override rather than hardcoded so the file still runs where the bundled browser IS installed. */
  const exe = process.env.CHROME_BIN || '/usr/bin/google-chrome-stable';
  const browser = await chromium.launch(fs.existsSync(exe) ? { executablePath: exe } : {});
  const page = await browser.newPage({ viewport: { width: 375, height: 740 }, deviceScaleFactor: 2 });
  const errors = [];
  page.on('console', m => m.type() === 'error' && errors.push(m.text()));
  page.on('pageerror', e => errors.push(String(e)));
  await page.goto(URL, { waitUntil: 'networkidle' });

  /* ---- 0. the tool panel really hides, so every hit test below means something ---- */
  await hideTools(page);
  ok(await page.evaluate(() => getComputedStyle(document.getElementById('tools')).visibility === 'hidden'),
    '0 · #tools se oculta de verdad antes de cualquier hit-test');
  await showTools(page);

  /* ---- 1. the walk reaches an enriched, incomplete draft in the editor ---- */
  await toEditor(page);
  let st = await gateState(page);
  ok(st.status === 'draft' && st.missing && st.missing.join() === 'weight_band',
    `1 · el borrador llega enriquecido y le falta EXACTAMENTE el nivel (missing=${st.missing})`);

  /* ---- 2. the button exists and is ALIVE once complete — so check 3's "disabled" can mean something ----
     Without this, `#publish[disabled]` is indistinguishable from "the walk never got here". */
  await setGate(page, 'G1');
  await step(page, 'nivel');
  st = await gateState(page);
  ok(st.hasBtn && st.disabled === false && st.missing.length === 0 && !/[Ff]alta/.test(st.why),
    `2 · con el nivel puesto, Publicar está VIVO en G1 y ya no se nombra ningún faltante ("${st.why}")`);

  /* ---- 3. G1 kills the button while incomplete, and SAYS WHAT is missing ---- */
  await toEditor(page); await setGate(page, 'G1');
  st = await gateState(page);
  ok(st.hasBtn && st.disabled === true, '3a · G1 · Publicar está muerto mientras falta el nivel');
  ok(/falta el nivel/i.test(st.why), `3b · G1 · la barra nombra QUÉ falta, no sólo QUE falta ("${st.why}")`);

  /* ---- 4. the three variants read ONE `missing()` — so nothing below is attributable to treatment ---- */
  const miss = {};
  for (const g of GATES) { await toEditor(page); await setGate(page, g); miss[g] = (await gateState(page)).missing.join(); }
  ok(miss.G1 === miss.G2 && miss.G2 === miss.G3 && miss.G1 === 'weight_band',
    `4 · las tres variantes leen el mismo missing() (${JSON.stringify(miss)})`);

  /* ---- 5. the bar's geometry is identical in all three; only G1 adds the `why` and the dead button ---- */
  const bars = {};
  for (const g of GATES) {
    await toEditor(page); await setGate(page, g); await hideTools(page);
    bars[g] = await page.evaluate(() => {
      const host = document.getElementById('stack').offsetParent ? document.getElementById('stack') : document.getElementById('tbar');
      const b = host.getBoundingClientRect();
      return { top: Math.round(b.top), h: Math.round(b.height), btns: host.querySelectorAll('.btn').length };
    });
    await showTools(page);
  }
  ok(bars.G2.top === bars.G3.top && bars.G2.h === bars.G3.h && bars.G2.btns === bars.G3.btns && bars.G2.btns === 2,
    `5a · G2 y G3 dibujan una barra byte-idéntica — sólo difieren AL TOCAR (${JSON.stringify(bars.G2)} vs ${JSON.stringify(bars.G3)})`);
  /* 5b was written for round 1's single-row savebar, where G1's sentence sat BESIDE the buttons and cost
     no height. In B's stacked foot it sits ABOVE them, so G1's bar is genuinely taller — and that height
     comes straight out of the form. Measured rather than asserted equal. */
  ok(bars.G1.btns === 2 && bars.G1.h >= bars.G2.h,
    `5b · en el pie apilado la frase de G1 cuesta ALTURA: ${bars.G1.h}px contra ${bars.G2.h}px de G2/G3 — ${bars.G1.h - bars.G2.h}px menos de formulario`);

  /* ---- 6. G3's only paint: a dot on the row the gate names, and on no other row ---- */
  const dots = {};
  for (const g of GATES) { await toEditor(page); await setGate(page, g); const s = await gateState(page); dots[g] = { n: s.missDots, k: s.missDotKeys.join() }; }
  ok(dots.G3.n === 1 && dots.G3.k === 'weight_band' && dots.G1.n === 0 && dots.G2.n === 0,
    `6a · el punto de "falta" existe SÓLO en G3 y SÓLO en la fila del nivel (${JSON.stringify(dots)})`);
  /* 6b EXISTS BECAUSE 6a PASSED AGAINST AN INVISIBLE DOT. The first draft painted it with a variable this
     theme renamed years ago, so it rendered as an 8x8 transparent square — counted, found, and green.
     A node count is not a measurement of something you can SEE. */
  await toEditor(page); await setGate(page, 'G3');
  const dotPaint = await page.evaluate(() => {
    const d = document.querySelector('.frow .miss'), cs = getComputedStyle(d);
    return { bg: cs.backgroundColor, w: d.getBoundingClientRect().width };
  });
  ok(!/rgba\(0, 0, 0, 0\)|transparent/.test(dotPaint.bg) && dotPaint.w >= 6,
    `6b · y ese punto tiene un color de verdad, no una variable inexistente (${dotPaint.bg}, ${dotPaint.w}px)`);

  /* ---- 7. copias: pre-filled to 1, and NOT a gate item in any variant ----
     `units` has no DB default, enrichment never casts it, admin_changeset lets a blank through — so without
     the pre-fill every game the new flow creates stays nil forever. 434/434 published have exactly 1. */
  const units = {};
  for (const g of GATES) { await toEditor(page); await setGate(page, g); const s = await gateState(page); units[g] = { row: s.unitsRow.trim(), inGate: s.missing.includes('units') }; }
  ok(units.G1.row.startsWith('1') && !units.G1.inGate && !units.G2.inGate && !units.G3.inGate,
    `7 · copias se pre-carga en 1 y NO es condición de la puerta en ninguna variante (${JSON.stringify(units)})`);

  /* ---- 8. THE GATE CANNOT TELL A BAD NAME FROM A GOOD ONE ----
     The real draft's name is a 62-char concatenation BGG never meant to send (bgg_client.ex:130's `.//` +
     SweetXml's `s`). It is a production bug, filed separately, and the gate is deliberately NOT designed
     around it. This check asserts that claim instead of leaving it as prose: the gate's items must be
     IDENTICAL under both names. If it ever goes red, someone has taught the gate a name heuristic. */
  await toEditor(page); await setGate(page, 'G1');
  const clean = await gateState(page);
  await setTool(page, 'nm', '1');
  const broken = await gateState(page);
  ok(clean.missing.join() === broken.missing.join() && broken.disabled === clean.disabled,
    `8a · la puerta no distingue el nombre roto del bueno (limpio=${clean.missing} roto=${broken.missing})`);
  ok(await page.evaluate(() => document.getElementById('ghname').textContent.includes('Korean edition')),
    '8b · el nombre roto REALMENTE se pinta (si no, 8a no probaría nada)');
  await setTool(page, 'nm', '0');

  /* ---- 9. the gate's one condition VANISHES for an expansion, in all three ----
     0 of 26 published expansions carry a nivel; 408 of 408 base games do. Without this lever "the gate
     requires nivel" is unfalsifiable. */
  const exp = {};
  for (const g of GATES) {
    await toEditor(page); await setGate(page, g); await setTool(page, 'exp', '1');
    const s = await gateState(page); exp[g] = { miss: s.missing.join(), dis: s.disabled, dots: s.missDots };
    await setTool(page, 'exp', '0');
  }
  ok(exp.G1.miss === '' && exp.G1.dis === false && exp.G2.miss === '' && exp.G3.miss === '' && exp.G3.dots === 0,
    `9 · para una expansión la puerta no tiene ninguna condición, en las tres (${JSON.stringify(exp)})`);

  /* ---- 10. 073:46's rule survives in all three: no BGG data, no publishing ----
     This is the half of the gate that WAS already drawn (075's `hasData()`), and it is not a variant. */
  const pend = {};
  for (const g of GATES) {
    await reset(page); await step(page, 'create'); await setGate(page, g);
    pend[g] = await page.evaluate(() => {
      const gm = window.byId(window.NEW);
      return { open: window.gateOpen(gm), enr: window.enrOf(gm) };
    });
  }
  ok(pend.G1.enr === 'pending' && !pend.G1.open && !pend.G2.open && !pend.G3.open,
    `10 · sin datos de BGG no se publica, en ninguna variante (${JSON.stringify(pend)})`);

  /* ---- 11. THE TAP — the only place G2 and G3 differ, and the reason 5a is not the whole story ---- */
  await toEditor(page); await setGate(page, 'G2');
  await tapPublish(page);
  let g2 = await gateState(page);
  ok(g2.dialogOpen && /falta el nivel/i.test(g2.dialogText) && g2.status === 'draft',
    `11a · G2 · el toque abre un confirm que NOMBRA lo que falta, y todavía NO publicó (${JSON.stringify({ d: g2.dialogOpen, s: g2.status })})`);
  /* 18 EXISTS BECAUSE A SCREENSHOT CAUGHT IT: the dialog is shared with 077, whose only caller was
     destructive, so `dlg-yes` carried danger red unconditionally and "Publicar igual" came out painted as a
     delete. Compared against the app's OWN danger colour rather than against a hardcoded hex, so a theme
     change cannot make this check quietly meaningless. */
  const dlgPaint = await page.evaluate(() => {
    const b = document.querySelector('[data-act="dlg-yes"]');
    const danger = getComputedStyle(document.documentElement).getPropertyValue('--color-danger').trim();
    const probe = document.createElement('span'); probe.style.color = danger;
    document.body.appendChild(probe); const resolved = getComputedStyle(probe).color; probe.remove();
    return { colour: getComputedStyle(b).color, danger: resolved, dan: b.classList.contains('dan') };
  });
  ok(!dlgPaint.dan && dlgPaint.colour !== dlgPaint.danger,
    `18 · "Publicar igual" NO está pintado de rojo de peligro — publicar no es destruir (${dlgPaint.colour} vs peligro ${dlgPaint.danger})`);
  await page.evaluate(() => document.querySelector('[data-act="dlg-yes"]').click());
  g2 = await gateState(page);
  ok(g2.status === 'published' && !g2.dialogOpen,
    '11b · G2 · "Publicar igual" sí publica — avisar no es prohibir');

  await toEditor(page); await setGate(page, 'G3');
  await tapPublish(page);
  const g3 = await gateState(page);
  ok(g3.status === 'published' && !g3.dialogOpen,
    '11c · G3 · el toque publica de una, sin decir nada — que es lo que hace el código HOY');

  await toEditor(page); await setGate(page, 'G1');
  await tapPublish(page);
  let g1 = await gateState(page);
  ok(g1.status === 'draft' && !g1.dialogOpen,
    '11d · G1 · tocar el botón muerto no hace nada');
  /* AND THE SAME THING THROUGH THE OTHER DOOR. This is the check that found G1's gate was pure paint:
     the walk's step 5 calls doPublish() the way any other caller would, and the first version of this page
     published a draft with no nivel while the button on screen was visibly dead. */
  await step(page, 'publish');
  g1 = await gateState(page);
  ok(g1.status === 'draft',
    '11e · G1 · y tampoco por el otro camino — la negativa vive en la función, no sólo en la pintura');

  /* ---- 12. NEGATIVE TEST — empty `missing()` and checks 3 and 6 must go RED ----
     Reached through `window` because a top-level function DECLARATION is the only kind the page's own
     closures resolve late enough for a harness override to reach (076 hit the const trap twice). */
  await toEditor(page); await setGate(page, 'G1');
  await page.evaluate(() => { window.__realMissing = window.missing; window.missing = () => []; window.render(); });
  const neg = await gateState(page);
  await setGate(page, 'G3');
  const negDots = (await gateState(page)).missDots;
  await page.evaluate(() => { window.missing = window.__realMissing; window.render(); });
  ok(neg.disabled === false && neg.why === '' && negDots === 0,
    `12 · anulando missing() la puerta desaparece — el check 3 y el 6 son falsificables (dis=${neg.disabled} why="${neg.why}" dots=${negDots})`);

  /* ---- 13. the lifecycle read-out is 075's dot + text, and it is NOT a control ----
     075:886 drew it that way and it is also the app-wide status rule. Despublicar is slice 079; this check
     exists so that adding a control here later cannot happen silently. */
  await toEditor(page);
  const life = await page.evaluate(() => {
    const el = document.querySelector('.gh-st');
    return { txt: el.textContent.trim(), dots: el.querySelectorAll('.dot').length, tag: el.tagName, btns: el.querySelectorAll('button').length };
  });
  ok(life.dots === 1 && life.btns === 0 && /^Borrador/.test(life.txt),
    `13a · el ciclo es un punto + texto, sin ningún control (${JSON.stringify(life)})`);
  const lifePaint = await page.evaluate(() => getComputedStyle(document.querySelector('.gh-st .dot')).backgroundColor);
  ok(!/rgba\(0, 0, 0, 0\)|transparent/.test(lifePaint),
    `13c · y el punto del ciclo se ve (${lifePaint}) — 13a pasó contra uno transparente`);
  await setGate(page, 'G3'); await step(page, 'publish');
  const life2 = await page.evaluate(() => document.querySelector('.gh-st').textContent.trim());
  ok(/^Publicado/.test(life2), `13b · y cambia de verdad al publicar ("${life2}")`);

  /* ---- 14. published: there is NO way back. The measurement, not a design ----
     `publish_game` -> :published, `retire_game` -> :retired, `restore_game` :retired -> :published. There
     is no :published -> :draft transition anywhere in the app, and `Retirar` means the club no longer HAS
     the game. This check records the absence so slice 079 starts from a number rather than from memory. */
  const back = await page.evaluate(() => {
    const acts = [...document.querySelectorAll('#tbar [data-act], #stack [data-act], #savebar [data-act]')].map(b => b.dataset.act).filter(a => a !== 'juegos' && a !== 'back');
    return { acts, publishBtn: !!document.getElementById('publish') };
  });
  ok(!back.publishBtn && !back.acts.includes('unpublish') && !back.acts.includes('retire'),
    `14 · publicado, la barra no ofrece ninguna vuelta atrás — despublicar NO EXISTE (acts=${back.acts})`);

  /* ---- 17. G1's explanation has to fit BESIDE two buttons in 375px ----
     Not a preference: `why` + `Guardar` + `Publicar` share one row, so the sentence gets whatever is left.
     Measured rather than eyeballed, and recorded in the README as G1's real cost. G2 and G3 pay nothing
     here because their bar carries no sentence at all. */
  await toEditor(page); await setGate(page, 'G1'); await hideTools(page);
  const crowd = await page.evaluate(() => {
    const w = document.querySelector('#tbar .why, #stack .why, #savebar .why') || document.createElement('span');
    const r = w.getBoundingClientRect();
    const lh = parseFloat(getComputedStyle(w).lineHeight) || 18;
    return { w: Math.round(r.width), h: Math.round(r.height), lines: Math.round(r.height / lh), txt: w.textContent.trim() };
  });
  await showTools(page);
  ok(crowd.w > 0, `17 · la explicación de G1 vive en ${crowd.w}px y ocupa ${crowd.lines} renglones ("${crowd.txt}")`);

  /* ---- 17b. G1's DEAD button is still the loudest thing in the bar ----
     d42's rule puts the primary at the trailing edge and gives it the filled treatment; `disabled` only
     drops its opacity (075's `.btn[disabled] { opacity: .42 }`). So under G1 the control you CANNOT use is
     a filled block, and the one you CAN use (`Guardar`) is text. Measured as painted area, not judged:
     if the dead primary is bigger, the bar's loudest element is the refusal. */
  await toEditor(page); await setGate(page, 'G1'); await hideTools(page);
  const weight = await page.evaluate(() => {
    const p = document.getElementById('publish').getBoundingClientRect();
    const gEl = document.querySelector('#stack .btn.sec') || document.querySelector('.btn.ghost') || document.getElementById('publish');
    const g = gEl.getBoundingClientRect();
    const cs = getComputedStyle(document.getElementById('publish'));
    return { pub: Math.round(p.width * p.height), save: Math.round(g.width * g.height), op: cs.opacity, fill: cs.backgroundColor };
  });
  await showTools(page);
  ok(weight.pub > 0 && weight.save > 0,
    `17b · en el pie apilado los dos botones ocupan lo mismo (${weight.pub}px² vs ${weight.save}px²) — el Publicar muerto se distingue sólo por opacidad ${weight.op} y relleno, no por tamaño`);

  /* ---- 16. THE TOAST BURIES THE FOOT — and A is out of its reach ----
     Round 1 found d55's 10000ms toast sitting on top of the action bar, with `elementFromPoint` at the
     button's own centre returning the snackbar. Round 2 turns that into a COMPARISON, because moving the
     CTA into 074's top bar takes it out of the toast's path entirely. Measured with a hit test in both. */
  const reach = {};
  for (const mo of ['A', 'B']) {
    await reset(page); await setMode(page, mo); await setGate(page, 'G3');
    await step(page, 'create'); await step(page, 'enriched'); await step(page, 'edit');
    await hideTools(page);
    reach[mo] = await page.evaluate(() => {
      const b = document.getElementById('publish'), s = document.getElementById('snack');
      const r = b.getBoundingClientRect();
      return {
        snackUp: s.classList.contains('show'),
        /* RESOLVED BY ANCESTRY, not by the leaf's own id/class: the point inside the snackbar lands on its
           inner <span>, which has neither — so reading the leaf reported "" and the check went red while
           the page was doing exactly what it was accused of. A hit test has to name the CONTAINER. */
        hit: (el => el ? (el.closest('#snack') ? 'snack' : el.closest('#stack') ? 'stack'
          : el.closest('#tbar') ? 'tbar' : el.id || el.className || el.tagName) : 'nada')
          (document.elementFromPoint(r.left + r.width / 2, r.top + r.height / 2)),
        y: Math.round(r.top)
      };
    });
    await page.screenshot({ path: path.join(OUT, `X-toast-${mo}.png`) });
    await showTools(page);
  }
  ok(reach.A.snackUp && reach.B.snackUp, `16a · en ambos el toast de d55 sigue vivo al llegar al editor (${JSON.stringify(reach)})`);
  ok(/snack/.test(reach.B.hit) && !/snack/.test(reach.A.hit),
    `16b · el toast tapa el Publicar de B (y=${reach.B.y}) y NO alcanza al de A (y=${reach.A.y}) — subirlo a la barra de 074 lo saca de su camino`);

  /* ================= RONDA 2 · ¿cuándo se vuelve real una edición? ================= */

  /* ---- 20. THE EDITOR IS A FULL-SCREEN DESTINATION ----
     Counted with offsetParent, never by reading the `hidden` attribute: 074 lost a round to a class whose
     `display` out-specified `[hidden] { display: none }`, so the page rendered the wordmark header UNDER
     the new bar while the check reported it gone. Negative-tested by removing the companion rule. */
  for (const mo of ['A', 'B']) {
    await toEditor(page, mo);
    const chrome = await page.evaluate(() => {
      const laid = id => { const e = document.getElementById(id); return !!(e && e.offsetParent); };
      return { hdr: laid('hdr'), tabs: laid('tabs'), pbar: laid('pbar'), tbar: laid('tbar'),
        foot: laid('stack') || laid('savebar'),
        backs: [...document.querySelectorAll('.back, .tb-back')].filter(e => e.offsetParent).length };
    });
    ok(!chrome.hdr && !chrome.tabs && !chrome.pbar && chrome.tbar && chrome.backs === 1
      && chrome.foot === (mo === 'B'),
      `20${mo} · ${mo} · sin wordmark, sin tabs, sin pbar; una barra, UN control de volver, y pie ${mo === 'B' ? 'presente' : 'AUSENTE de verdad'} (${JSON.stringify(chrome)})`);
  }
  /* the negative test: put the companion rule back out of reach and the count must go wrong. */
  await page.evaluate(() => {
    const st = document.createElement('style');
    st.id = 'neg'; st.textContent = '.hdr[hidden]{display:flex !important}';
    document.head.appendChild(st);
  });
  const negChrome = await page.evaluate(() => !!document.getElementById('hdr').offsetParent);
  await page.evaluate(() => document.getElementById('neg')?.remove());
  ok(negChrome, '20neg · y el check 20 es falsificable: forzando el display el wordmark reaparece');

  /* ---- 21. A's dirty state is structurally absent, not merely unused ---- */
  await toEditor(page, 'A'); await step(page, 'nivel');
  const aClean = await page.evaluate(() => ({ dirty: window.dirty(), writes: window.TAPS.writes }));
  await toEditor(page, 'B'); await step(page, 'nivel');
  const bDirty = await page.evaluate(() => ({ dirty: window.dirty(), writes: window.TAPS.writes }));
  ok(aClean.dirty === false && aClean.writes === 1 && bDirty.dirty === true && bDirty.writes === 0,
    `21 · A escribe al elegir y nunca queda sucio; B queda sucio y todavía no escribió (A=${JSON.stringify(aClean)} B=${JSON.stringify(bDirty)})`);

  /* ---- 22. G1 IS ONLY BUILDABLE IN B — the cross-round dependency, asserted not assumed ----
     074's bar is `‹ · título · CTA`. There is no slot for a sentence, so a blocked Publicar in A cannot say
     why. This is the thing that makes round 1 and round 2 not independent. */
  await toEditor(page, 'A'); await setGate(page, 'G1');
  const aWhy = await page.evaluate(() => {
    const w = document.querySelector('#tbar .why');
    return { why: w ? w.textContent.trim() : null, dead: document.getElementById('publish').disabled };
  });
  ok(aWhy.dead === true && aWhy.why === null,
    `22 · en A el Publicar de G1 está muerto y NO TIENE DÓNDE EXPLICARSE — la barra de 074 no tiene slot para una frase (${JSON.stringify(aWhy)})`);

  /* ---- 23. how much form fits above the fold ----
     The first version compared A and B at G3 only and reported 6/6 vs 6/6 — true, and useless: the last
     row ends at 608 and B's G3 floor is 611, so it clears by THREE PIXELS. The interesting number is
     across the gates, because G1's sentence pushes B's foot from 129px to 155px and takes the last row
     with it. Measured per gate rather than averaged into a verdict. */
  const fold = {};
  for (const mo of ['A', 'B']) for (const g of GATES) {
    await toEditor(page, mo); await setGate(page, g); await hideTools(page);
    fold[mo + g] = await page.evaluate(() => {
      /* OFF THE SCREEN, NOT THE ATTRIBUTE. The first version asked `stack.hidden` and hardcoded 740 —
         which was false while `.stack` was still laid out for want of its `[hidden]` companion. */
      const stack = document.getElementById('stack');
      const floor = stack.offsetParent ? stack.getBoundingClientRect().top : 740;
      const rows = [...document.querySelectorAll('.frow')];
      return { ok: rows.filter(r => r.getBoundingClientRect().bottom <= floor + 0.5).length, floor: Math.round(floor) };
    });
    await showTools(page);
  }
  ok(fold.AG1.ok === 6 && fold.AG2.ok === 6 && fold.AG3.ok === 6,
    `23a · en A las 6 filas entran enteras con cualquier puerta (piso 740px siempre)`);
  ok(fold.BG3.ok === 6 && fold.BG1.ok === 5,
    `23b · en B la frase de G1 se come la última fila: G3 ${fold.BG3.ok}/6 (piso ${fold.BG3.floor}) · G1 ${fold.BG1.ok}/6 (piso ${fold.BG1.floor}) — y G3 zafa por 3px`);

  /* ---- 23c. B's resting foot holds TWO DEAD BUTTONS ----
     Found in a screenshot, not in a number. On a fresh draft `Publicar` is blocked by G1 and `Guardar` is
     dead because nothing is staged yet — so 155px at the foot of the page, the heaviest thing on screen,
     is two controls you cannot press. 064 banned disabled buttons outright; round 1 already counted the
     sixth, and this is the seventh in the same view as the sixth. A does not have this state at all,
     because it has no Guardar and its CTA is 36px of text. */
  await toEditor(page, 'B'); await setGate(page, 'G1');
  const deadFoot = await page.evaluate(() => {
    const bs = [...document.querySelectorAll('#stack .btn')];
    return { n: bs.length, dead: bs.filter(b => b.disabled).length,
      h: Math.round(document.getElementById('stack').getBoundingClientRect().height) };
  });
  await toEditor(page, 'A'); await setGate(page, 'G1');
  const deadTop = await page.evaluate(() => {
    const bs = [...document.querySelectorAll('#tbar .btn')];
    return { n: bs.length, dead: bs.filter(b => b.disabled).length };
  });
  ok(deadFoot.n === 2 && deadFoot.dead === 2 && deadTop.n === 1 && deadTop.dead === 1,
    `23c · en reposo B ofrece ${deadFoot.dead} de ${deadFoot.n} botones MUERTOS en ${deadFoot.h}px de pie; A ofrece ${deadTop.dead} de ${deadTop.n}, de 36px`);

  /* ---- 24. cuántos toques cuesta completar y publicar ----
     THE HONEST ANSWER, and it is not the one the framing implied: for the PUBLISH path they cost the same,
     because Publicar has always saved first (form.ex:84-92 -> after_save). The difference is not in taps. */
  const cost = {};
  for (const mo of ['A', 'B']) {
    await toEditor(page, mo); await setGate(page, 'G3');
    await page.evaluate(() => { window.TAPS.taps = 0; window.TAPS.writes = 0; });
    await page.evaluate(() => document.querySelector('[data-field="weight_band"]').click());
    await page.evaluate(() => document.querySelector('[data-pick="weight_band"][data-val="medio"]').click());
    await tapPublish(page);
    cost[mo] = await page.evaluate(() => ({ taps: window.TAPS.taps, writes: window.TAPS.writes, st: window.byId(window.S.editing).status }));
  }
  ok(cost.A.st === 'published' && cost.B.st === 'published' && cost.A.taps === cost.B.taps,
    `24 · completar y publicar cuesta LO MISMO en toques: A ${cost.A.taps} · B ${cost.B.taps} (escrituras A ${cost.A.writes} · B ${cost.B.writes})`);

  /* ---- 25. y si te vas a la mitad — donde SÍ difieren ---- */
  const leave = {};
  for (const mo of ['A', 'B']) {
    await toEditor(page, mo); await setGate(page, 'G3');
    await page.evaluate(() => document.querySelector('[data-field="weight_band"]').click());
    await page.evaluate(() => document.querySelector('[data-pick="weight_band"][data-val="medio"]').click());
    await step(page, 'leave');
    const asked = await page.evaluate(() => document.getElementById('dscrim').classList.contains('open'));
    if (asked) await page.evaluate(() => document.querySelector('[data-act="dlg-yes"]').click());
    leave[mo] = { asked, band: await page.evaluate(() => window.byId(window.NEW).weight_band) };
  }
  ok(leave.A.asked === false && leave.A.band === 'medio' && leave.B.asked === true && leave.B.band === null,
    `25 · salir a la mitad: A no pregunta y el nivel QUEDA · B pregunta y al salir el nivel SE PIERDE (${JSON.stringify(leave)})`);

  /* ---- 15. no console errors ---- */
  ok(errors.length === 0, `15 · sin errores de consola${errors.length ? ' — ' + errors.slice(0, 2).join(' | ') : ''}`);

  /* ---- screenshots ---- */
  for (const g of GATES) {
    await toEditor(page); await setGate(page, g); await hideTools(page);
    await page.screenshot({ path: path.join(OUT, `${g}-borrador-incompleto.png`) });
    await showTools(page);
  }
  await toEditor(page); await setGate(page, 'G2'); await step(page, 'publish');
  await hideTools(page); await page.screenshot({ path: path.join(OUT, 'G2-confirm.png') }); await showTools(page);
  await page.evaluate(() => document.querySelector('[data-act="dlg-no"]').click());
  await toEditor(page); await setGate(page, 'G1'); await step(page, 'nivel');
  await hideTools(page); await page.screenshot({ path: path.join(OUT, 'G1-completo.png') }); await showTools(page);

  console.log(log.join('\n'));
  const pass = log.filter(l => l.startsWith('PASS')).length;
  console.log(`\n${pass}/${log.length}  ·  capturas en ${OUT}`);
  await browser.close();
  process.exit(pass === log.length ? 0 : 1);
})();
