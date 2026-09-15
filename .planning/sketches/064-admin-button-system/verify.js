/* Headless-Chrome check for sketch 064 (admin button system). Run from the repo root:
     python3 -m http.server 8765 &
     node .planning/sketches/064-admin-button-system/verify.js
   Env: PLAYWRIGHT_CORE, SKETCH_URL, SHOTS_DIR (default <os tmp>/sketch-064-shots). */
const fs = require('fs'), path = require('path'), os = require('os');
function loadPlaywright() {
  const tries = [process.env.PLAYWRIGHT_CORE, 'playwright-core'].filter(Boolean);
  const npx = path.join(os.homedir(), '.npm', '_npx');
  if (fs.existsSync(npx)) for (const d of fs.readdirSync(npx)) tries.push(path.join(npx, d, 'node_modules', 'playwright-core'));
  for (const t of tries) { try { return require(t); } catch (_) {} }
  console.error('playwright-core not found'); process.exit(2);
}
const { chromium } = loadPlaywright();
const URL = process.env.SKETCH_URL || 'http://127.0.0.1:8765/.planning/sketches/064-admin-button-system/index.html';
const OUT = process.env.SHOTS_DIR || path.join(os.tmpdir(), 'sketch-064-shots'); fs.mkdirSync(OUT, { recursive: true });
const log = []; const ok = (c, m) => log.push((c ? 'PASS ' : 'FAIL ') + m);
(async () => {
  const b = await chromium.launch({ channel: 'chrome', headless: true });
  const p = await b.newPage({ viewport: { width: 420, height: 900 }, deviceScaleFactor: 2 });
  const errs = []; p.on('pageerror', e => errs.push(e.message)); p.on('console', m => m.type() === 'error' && !/404/.test(m.text()) && errs.push(m.text()));
  await p.goto(URL); await p.evaluate(() => document.fonts.ready);
  const J = (f, a) => p.evaluate(f, a), click = async s => { await p.click(s); await p.waitForTimeout(250); };
  /* WCAG contrast of a button label against the color actually behind it */
  const audit = () => J(() => {
    const rgb = s => { const srgb = /^color\(srgb/.test(s); const m = s.replace(/^color\(srgb/, '').match(/[\d.]+/g).map(Number); const k = srgb ? 255 : 1; const alpha = srgb ? (/\//.test(s) ? m[3] : 1) : (m[3] ?? 1); return { r: m[0] * k, g: m[1] * k, b: m[2] * k, a: alpha }; };
    const lum = c => [c.r, c.g, c.b].map(v => { v /= 255; return v <= .03928 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4; }).reduce((s, v, i) => s + v * [.2126, .7152, .0722][i], 0);
    const bgOf = el => { let stack = []; for (let n = el; n; n = n.parentElement) { const c = rgb(getComputedStyle(n).backgroundColor); if (c.a > 0) { stack.push(c); if (c.a === 1) break; } } let base = { r: 255, g: 255, b: 255 }; for (const c of stack.reverse()) base = { r: c.r * c.a + base.r * (1 - c.a), g: c.g * c.a + base.g * (1 - c.a), b: c.b * c.a + base.b * (1 - c.a) }; return base; };
    const btns = [...document.querySelectorAll('.btn')];
    const res = btns.map(el => { const cs = getComputedStyle(el), r = el.getBoundingClientRect(), fg = rgb(cs.color), bg = bgOf(el); const L1 = lum(fg), L2 = lum(bg); return { role: el.dataset.role, label: el.textContent.trim(), h: Math.round(r.height), radius: cs.borderRadius, font: cs.fontSize + '/' + cs.fontWeight, ratio: (Math.max(L1, L2) + .05) / (Math.min(L1, L2) + .05), disabled: el.disabled }; });
    const cards = [...document.querySelectorAll('[data-moment]')].map(c => ({ cap: c.querySelector('.cap').textContent, pri: c.querySelectorAll('.b-pri').length, dan: c.querySelectorAll('.b-pri.b-dan').length }));
    const paint = role => { const el = document.querySelector('.b-' + role); const cs = getComputedStyle(el); return cs.backgroundColor + '|' + cs.boxShadow + '|' + cs.color; };
    return { res, cards, paints: ['pri', 'sec', 'ter', 'dan'].map(paint), overflow: document.documentElement.scrollWidth > innerWidth + 1 };
  });
  for (const theme of ['light', 'dark']) {
    await click(`[data-theme-set="${theme}"]`);
    for (const s of ['s1', 's2', 's3']) {
      await click(`[data-sys="${s}"]`); const a = await audit(); const tag = `${s} ${theme}`;
      ok(!a.overflow, `${tag}: no horizontal overflow at 420px`);
      ok(a.res.every(x => x.h === 44 && x.radius === '8px' && x.font === '14px/600'), `${tag}: every button is 44px / 8px radius / 14px 600 ` + a.res.filter(x => !(x.h === 44 && x.radius === '8px' && x.font === '14px/600')).map(x => x.label + ' ' + x.h + ' ' + x.radius + ' ' + x.font).join(', '));
      ok(a.res.every(x => !x.disabled), `${tag}: no disabled buttons`);
      ok(a.cards.every(c => c.pri <= 1 && c.dan === 0), `${tag}: at most one Principal per block; Peligro is never Principal`);
      ok(new Set(a.paints).size === 4, `${tag}: the four roles are painted four different ways`);
      const low = a.res.filter(x => x.ratio < 4.5); ok(low.length === 0, `${tag}: every button label ≥ 4.5:1 contrast ` + low.map(x => `${x.label} ${x.ratio.toFixed(2)}`).join(', '));
      await p.screenshot({ path: `${OUT}/${s}-${theme}-top.png`, fullPage: false });
      await J(() => scrollTo(0, document.querySelectorAll('[data-moment]')[7].offsetTop - 60)); await p.screenshot({ path: `${OUT}/${s}-${theme}-mid.png` });
      await J(() => scrollTo(0, document.querySelectorAll('[data-moment]')[12].offsetTop - 60)); await p.screenshot({ path: `${OUT}/${s}-${theme}-end.png` }); await J(() => scrollTo(0, 0));
    }
  }
  await click('[data-theme-set="light"]'); await click('[data-sys="s1"]');
  ok(await J(() => { const t = [...document.querySelectorAll('[data-moment]')].filter(c => /Editor · Estado/.test(c.textContent));
    const roles = t.map(c => [...c.querySelectorAll('.btn')].map(x => x.dataset.role + ':' + x.textContent.trim()).join(','));
    return roles.join(' / ') === 'pri:Publicar / sec:Guardar,pri:Publicar / dan:Retirar de la web / dan:Retirar,pri:Guardar / sec:Restaurar'; }), 'Estado: Guardar only with changes; Publicar is the draft Principal; Retirar is Peligro; Restaurar Secundaria');
  ok(await J(() => [...document.querySelectorAll('.actions')].every(r => { const bs = [...r.querySelectorAll('.btn')]; const pi = bs.findIndex(x => x.classList.contains('b-pri')); return pi === -1 || pi === bs.length - 1; })), 'Principal is always last in its action row');
  await J(() => document.getElementById('f-add').scrollIntoView()); await click('[data-act="add"]');
  ok(await J(() => document.getElementById('f-add').getAttribute('aria-invalid') === 'true' && /Pegá un ID/.test(document.getElementById('f-add-err').textContent) && document.activeElement.id === 'f-add'), 'Agregar with an empty field validates on tap (not disabled) and focuses the field');
  await p.fill('#f-add', '224517'); ok(await J(() => !document.getElementById('f-add-err').textContent), 'typing clears the error');
  await p.setViewportSize({ width: 1300, height: 1000 }); await click('[data-vp="desk"]');
  for (const s of ['s1', 's2', 's3']) { await click(`[data-sys="${s}"]`); ok(!(await J(() => document.documentElement.scrollWidth > innerWidth + 1)), `desk ${s}: no overflow`); await p.screenshot({ path: `${OUT}/${s}-desk.png` }); }
  ok(errs.length === 0, 'no JS errors ' + errs.join(' | '));
  console.log(log.join('\n')); console.log(`\n${log.filter(l => l.startsWith('PASS')).length}/${log.length} passed · screenshots in ${OUT}`); await b.close();
  process.exitCode = log.some(l => l.startsWith('FAIL')) ? 1 : 0;
})().catch(e => { console.log(log.join('\n')); console.error('CRASH', e.message); process.exit(1); });
