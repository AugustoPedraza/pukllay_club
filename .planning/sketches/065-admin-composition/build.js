/* Sketch 065 — admin composition.
   Assembles ONE navigable admin app out of the shipped sketches 059–064 instead of re-designing them.
   Every page body, every row builder and the whole stylesheet are sliced verbatim out of the source
   sketches, so a drift fix has to be made THERE (in 060/061/062/063) and re-run here — this file can
   never quietly diverge from what those sketches say.

   What comes from where:
     CSS         063 (cumulative: 059 shell · 060 dash · 061 juegos · 062 lists · 063 editor · 064 buttons)
     icons+shell 063 (header, drawer, tab bar, account sheet, row(), group())
     Admin home  060 (boxData/box/panelBody)
     Juegos      061 (add form, search, chips, rows, snackbar plumbing)
     Web/…/Staff 062 (webBody, secBody, estBody, asgBody, nivBody, staffBody, vAct, submitV)
     Editor      063 (editBody and everything it calls, eAct)
   The glue below is only what a composition needs and no single sketch could own: one router, one
   render, one event layer, the walk, and the phone-keyboard behaviour 059/061 flagged and never tested.

   Run:  node .planning/sketches/065-admin-composition/build.js
*/
const fs = require('fs'), path = require('path');
const DIR = path.join(__dirname, '..');
const read = d => fs.readFileSync(path.join(DIR, d, 'index.html'), 'utf8');
const SRC = { s60: read('060-admin-panel-entries'), s61: read('061-admin-juegos-page'), s62: read('062-admin-list-rows'), s63: read('063-admin-game-editor') };

/* slice(src, from, to) — everything between two anchors that really exist, or throw loudly. */
function slice(src, from, to, { incl = true } = {}) {
  const a = src.indexOf(from);
  if (a < 0) throw new Error(`build: anchor not found: ${JSON.stringify(from.slice(0, 60))}`);
  const b = src.indexOf(to, a + from.length);
  if (b < 0) throw new Error(`build: end anchor not found: ${JSON.stringify(to.slice(0, 60))}`);
  return src.slice(a, incl ? b + to.length : b);
}
/* cut(text, from, to) — drop an interior block the composition replaces (one shell, not five). */
function cut(text, from, to) {
  const a = text.indexOf(from);
  if (a < 0) throw new Error(`build: cut anchor not found: ${JSON.stringify(from.slice(0, 60))}`);
  const b = text.indexOf(to, a + from.length);
  if (b < 0) throw new Error(`build: cut end not found: ${JSON.stringify(to.slice(0, 60))}`);
  return text.slice(0, a) + text.slice(b);
}

/* ---------- CSS: 063's whole stylesheet, unchanged ---------- */
const CSS = slice(SRC.s63, '<style>', '</style>').replace(/^<style>\n?/, '').replace(/<\/style>$/, '');

/* ---------- icons + the 059 shell, from 063 ---------- */
const ICONS = slice(SRC.s63, 'const P = {', 'const ic = (n, cls', { incl: false });
const IC_FN = slice(SRC.s63, 'const ic = (n, cls', '\n');
const ICON_ADD = ['Object.assign(P, {\n  archive:', 'Object.assign(P, {\n  eyeSlash:', "Object.assign(P, { sparkle:"]
  .map(a => slice(SRC.s63, a, '});')).join('\n');

/* SCREENS/row()/drawer/tabBar/accountSheet/pageHead — 063 has the richest row() (extra, wrap, avatarText)
   and the only SCREENS map with both drill-downs (seccion, asignar). */
const SHELL = slice(SRC.s63, 'const USER = {', '/* ================= 063: game editor ================= */', { incl: false });

/* ---------- 060: the page head + the Admin home dashboard ----------
   pageHead() lives in 060/061/062 but not 063 (the editor builds its own head), so the composition
   takes 060's — the one that knows Admin is the home and has no back row. */
const HOME60 = slice(SRC.s60, 'function pageHead() {', '\n}\n')
  + slice(SRC.s60, '/* ================= 060: the Admin home page', 'const panelBody = ()', { incl: false })
  + slice(SRC.s60, 'const panelBody = ()', '\n');

/* ---------- 061: Juegos ---------- */
const JUEGOS61 = slice(SRC.s61, '/* ================= 061: Juegos — add form', '\nfunction adminBody()', { incl: false })
  /* the composition owns refreshList/refreshAdd/syncBadges/flashRow/snack (they must know about 062's lists too) */
  .replace(/\/\* partial re-renders keep focus[\s\S]*?^}\n/m, '');

/* ---------- 062: Web · sección · Estantes · Asignar · Revisar niveles · Staff ---------- */
/* NB: that banner text appears twice in 062 (once over its CSS block, once over its JS). Anchor on the
   JS one's second line, or the slice swallows the whole file. */
let LISTS62 = slice(SRC.s62, "   Every list reuses 061's ONE row anatomy",
  '\nconst publicBody = ()', { incl: false });
LISTS62 = '/* ================= 062: Web · sección · Estantes · Asignar · Revisar niveles · Staff\n' + LISTS62;
/* The counters live in 062 — the only sketch whose DATA() is fully derived from live state. Every
   other sketch's DATA()/cnt() is a poorer copy of this one, and the composition must use this one or
   the Admin boxes and the tab badges drift away from the pages. */
const COUNTERS = slice(SRC.s62, '/* ONE counter source.', "\n  return n ? String(n) : '';\n}");
/* one shell, one router, one patch: drop 062's copies */
LISTS62 = cut(LISTS62, '\nfunction adminBody() {', '\nfunction move(scope, id, dir)');

/* The three club levels are named in BOTH 062 (Revisar niveles, sección por nivel) and 063 (the Nivel
   sheet). 062 used to hold names only and 063 names + meanings, so composing them collided on one
   `const BANDS`. 062 now carries 063's shape verbatim — asserted here so the two can never drift
   apart again silently, and the duplicate is dropped from 063's slice. */
const VOCAB = slice(SRC.s63, 'const BANDS = {', "const implied = w => w < 1.9 ? 'd' : w <= 3.1 ? 'i' : 'e';   // Vocabulary.implied_weight_band/1");
if (!SRC.s62.includes(VOCAB)) throw new Error('build: 062 and 063 disagree about BANDS/implied — the level vocabulary must be identical in both');

/* R7: the save bar (.ebar.inline) and the settings panel (.sgroup.apanel) are ONE component shared by
   062 (a sección) and 063 (the game editor) — 062 used to carry a second, divergent save bar (.saverow).
   065 renders 062's markup against 063's stylesheet, so this block has to be byte-identical in both or
   the composed page would not look like the sketch it came from. */
const R7 = slice(SRC.s63, '/* ================= 065 R7: one save bar', '#device .lhead > :is(.obtn, .b-pri, .b-sec) { margin: 0; }');
if (!SRC.s62.includes(R7)) throw new Error('build: 062 and 063 disagree about the R7 save-bar/settings-panel block — it must be identical in both');
/* R7b: the chip row is the admin's one "pick one of N" control (062's Estantes view switch as well as
   061's filters, whose CSS 063 carries), and the grouped-list seam is 062 markup rendered against 063's
   stylesheet — so this block is shared the same way and guarded the same way. */
const R7B = slice(SRC.s63, '/* ================= 065 R7b: one control for "pick one of N"', '#device main .grp .gnote { margin: 0 16px 12px 76px; }');
if (!SRC.s62.includes(R7B)) throw new Error('build: 062 and 063 disagree about the R7b chip/grouped-list block — it must be identical in both');
/* row() is the ONE row anatomy (059's, richest in 063) and 065 takes 063's copy — so when R7b taught it
   `type` (a sheet's committing action is a submit ROW, never a footer button) both copies had to learn it. */
const ROWFN = slice(SRC.s63, '/* 065 R7b: `type`.', "${chev && !isStatic ? ic('chevR', 'chev') : ''}</${tag}>`;\n}");
if (!SRC.s62.includes(ROWFN)) throw new Error('build: 062 and 063 disagree about row() — the one row anatomy must be identical in both');
/* R8: the ONE Estantes page. Its action strip (.gacts), its page-level secondary action (.pacts) and
   a row's expansion (.gexp) are 062 markup rendered against 063's stylesheet, so the block is shared
   and guarded the same way as R7/R7b. */
const R8 = slice(SRC.s63, '/* ================= 065 R8: ONE Estantes page', '#device main .gsub .mi .dot { display: inline-block; vertical-align: -1px; margin-right: 5px; }');
if (!SRC.s62.includes(R8)) throw new Error('build: 062 and 063 disagree about the R8 Estantes block — it must be identical in both');
/* R9: the estante rail. Same shape as R7/R7b/R8 — 062 markup against 063's stylesheet — and guarded
   the same way. It carries one extra guard the others do not need: the rail IS the app's own carousel,
   so the four numbers `carousel_row.ex`'s moduledoc calls a co-dependent set (edge-fade width, rail
   gap, card width, side gutter) are checked against `assets/css/app.css` itself. Three must match
   production's ≤480px values verbatim; the gutter is the admin page's 16px and is the one deliberate
   difference, measured in the README rather than assumed harmless. If production retunes the set, this
   throws instead of letting the sketch quietly describe a rail the app no longer has. */
const R9 = slice(SRC.s63, '/* ================= 065 R9: the estante as a RAIL', '#device main .ezones .chip::after { top: 0; bottom: 0; }');
if (!SRC.s62.includes(R9)) throw new Error('build: 062 and 063 disagree about the R9 rail block — it must be identical in both');
/* R10: one action system. The rail is the shipped Estantes page as of R10 (the developer overrode R9's
   measured verdict), so the rail's own navigation — the zone bar — closes the R9 block above, and the
   cross-context action rules are their own block. Same shape, same guard: 062 markup against 063's
   stylesheet, byte-identical in both or the composed page would not look like the sketch it came from. */
const R10 = slice(SRC.s63, '/* ================= 065 R10: ONE action system', '#device main :is(.sgroup, .sbox.rows) :is(button, label, a).srow { min-height: 44px; }');
if (!SRC.s62.includes(R10)) throw new Error('build: 062 and 063 disagree about the R10 action-system block — it must be identical in both');
/* and the A/C rail variants are deleted, not hidden: no `V.est` switch, no `.map` recipe, anywhere. */
for (const [k, src] of Object.entries({ s62: SRC.s62, s63: SRC.s63 }))
  if (/V\.est\s*(=|===|!==|\?)|erail-wrap\.map|data-est=/.test(src))
    throw new Error(`build: ${k} still carries a trace of R9's A/C variants (V.est / .map / data-est) — R10 deletes them`);
{
  const app = fs.readFileSync(path.join(DIR, '..', '..', 'assets', 'css', 'app.css'), 'utf8');
  const prod = slice(app, '@media (max-width: 480px) {', '\n}\n');
  const want = [['card width', /\.pk-poster-card \{\s*width: (\d+)px/, 96, '--etile'],
                ['rail gap', /\.pk-rail \{\s*gap: (\d+)px/, 10, '--egap'],
                ['edge fade', /\.pk-rail-wrap::before,\s*\n\s*\.pk-rail-wrap::after \{\s*\n?\s*width: (\d+)px/, 16, '--efade']];
  for (const [what, re, n, tok] of want) {
    const m = prod.match(re);
    if (!m || +m[1] !== n) throw new Error(`build: production's ${what} is ${m ? m[1] : '?'}px, the R9 rail declares ${n}px (${tok}) — the co-dependent set drifted`);
    if (!new RegExp(`${tok}: ${n}px`).test(R9)) throw new Error(`build: the R9 rail no longer declares ${tok}: ${n}px`);
  }
  if (!/--pk-gutter: 0\.875rem/.test(prod)) throw new Error("build: production's ≤480px gutter is no longer 0.875rem — the R9 README's peek measurement is derived from it");
}
/* and the targeted-search registry, which 062 and the glue each hold a copy of (the glue's has to know
   about 061's Juegos regions too, so it cannot simply be sliced out of 062 — but the 062 half must
   match, or typing in a search would blink in the composition and not in the sketch). */
const QREG62 = slice(SRC.s62, "const QREG = {", '\n');
if (!fs.readFileSync(path.join(__dirname, 'glue.js'), 'utf8').includes(QREG62))
  throw new Error('build: 062 and glue.js disagree about QREG — one region per search, defined identically');

/* ---------- 063: the game editor ---------- */
let EDITOR63 = slice(SRC.s63, '/* ================= 063: game editor ================= */', '\nconst NOTES = `', { incl: false });
/* 063 restates the shell helpers ($ , esc, nf, joinY, meta, slotIco, txt, w2) that SHELL already exports */
EDITOR63 = cut(EDITOR63, "const $ = sel => device.querySelector(sel);", "\n/* Real data shapes: Game.admin_changeset");
/* and its own openAct/snack/patch/sync/placeholder pages — the composition has the real ones */
EDITOR63 = cut(EDITOR63, "/* ---- placeholder pages (other admin screens live in 060-062) ---- */", "\n/* ---- sheets (059 row anatomy");
EDITOR63 = cut(EDITOR63, "\nfunction openAct(steps, opener) {", "\nfunction save(then) {");
/* 063 pins the app to the editor on load; the composition starts at Admin */
EDITOR63 = EDITOR63.replace("S.screen = 'editar';\n", '').replace(/^function cnt\(k\).*$/m, '');
/* the level vocabulary is 062's (identical, asserted above) */
EDITOR63 = EDITOR63.replace(VOCAB, '');

const GLUE = fs.readFileSync(path.join(__dirname, 'glue.js'), 'utf8');
const CHROME = fs.readFileSync(path.join(__dirname, 'chrome.html'), 'utf8');

const OUT = `<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Sketch 065 — Admin, composed</title>
<link rel="stylesheet" href="../themes/default.css">
<style>
/* ===================================================================================
   Stylesheet: sketch 063's, verbatim (it is the cumulative one — 059 shell, 060 boxes,
   061 Juegos, 062 lists, 063 editor, 064 buttons). Generated by build.js; edit 063.
   =================================================================================== */
${CSS}
/* ================= 065 only: what a composed walk needs =================
   Nothing here restyles a page. It covers the two things no single sketch could own:
   the phone soft keyboard (059/061 flagged it, nobody tested it) and the walk chrome. */
  /* iOS zooms the page in when a focused field's text is under 16px. Every admin field was 14-15px,
     and the shipped answer was "fix it with the viewport meta" — but maximum-scale=1 also kills
     pinch-zoom for everyone. Instead: fields grow to 16px on touch pointers only. */
  @media (pointer: coarse) {
    #device :is(.tin, .field input, .sfield input, .title-in, .desc-in, textarea) { font-size: 16px; }
    .polish #device .tin, #device .polish .tin, .polish .tin, .polish .sfield input, .polish .tin.desc-in { font-size: 16px; }
  }
  /* The soft keyboard covers the bottom of the screen. A bottom tab bar there is either hidden behind
     the keyboard (iOS, which doesn't resize the layout viewport) or pressed right against its top row
     (Android), where it gets mis-tapped. So while a field has focus the tab bar leaves. */
  .device .tabs { transition: transform var(--duration-base) var(--ease-out-soft); }
  .device.kbd .tabs { transform: translateY(100%); pointer-events: none; }
  .device.kbd.desk .tabs { transform: none; pointer-events: auto; }
  /* the keyboard itself, so the composition can be judged and asserted at a real height */
  .kbdsim { position: absolute; left: 0; right: 0; bottom: 0; height: var(--kbh, 292px); z-index: 80;
    background: repeating-linear-gradient(90deg, #b9b3c4 0 12.5%, #cdc7d6 12.5% 25%); border-top: 1px solid #9a93a8;
    display: flex; align-items: flex-start; justify-content: center; padding-top: 6px; font: 11px system-ui; color: #4b4356; letter-spacing: .08em; }
  :root[data-theme="dark"] .kbdsim { background: repeating-linear-gradient(90deg, #2b2438 0 12.5%, #3a3149 12.5% 25%); border-top-color: #4a4159; color: #b2a8c2; }
  /* with the keyboard up the page keeps its own bottom room, and any sheet sits on top of the keyboard */
  .device.kbd .scroller { padding-bottom: calc(var(--kbh, 292px) + 16px); }
  .device.kbd .sheet { bottom: var(--kbh, 292px); max-height: calc(100% - var(--kbh, 292px) - 24px); }
  .device.kbd .snack { bottom: calc(var(--kbh, 292px) + 12px); }
  .device.kbd.desk .scroller { padding-bottom: 0; }
  .device.kbd.desk .sheet { bottom: auto; max-height: none; }

  /* walk chrome (not part of the design) */
  #walk { display: flex; gap: 6px; align-items: center; flex-wrap: wrap; }
  #walk .step-n { opacity: .6; font-variant-numeric: tabular-nums; }
  .stab.done { opacity: .5; }
</style>
</head>
<body>
${CHROME}
<script>
${ICONS}${IC_FN}
${ICON_ADD}

/* ================= from 059/063: shell (header, drawer, tab bar, account sheet, one row anatomy) ================= */
${SHELL}
/* ================= from 062: the one counter source (DATA/cnt) ================= */
${COUNTERS}
/* ================= from 060: the page head + the Admin home dashboard ================= */
${HOME60}
/* ================= from 061: Juegos ================= */
${JUEGOS61}
/* ================= from 062: Web · sección · Estantes · Asignar · Revisar niveles · Staff ================= */
${LISTS62}
/* ================= from 063: the game editor ================= */
${EDITOR63}
/* ================= 065: the composition itself ================= */
${GLUE}
</script>
</body>
</html>
`;
fs.writeFileSync(path.join(__dirname, 'index.html'), OUT);
console.log('065/index.html written · ' + OUT.split('\n').length + ' lines');
