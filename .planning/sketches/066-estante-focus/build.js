/* Sketch 066 — estante focus (01.8.2 D-08).
   Takes 065's built page VERBATIM and adds only what this question needs, so 065 stays the design
   source for everything else:
     1. single-open estantes, the opened header scrolled flush under the sticky header, with a runway
        below the last estante so the scroll is always reachable (measured: C short 18px, D short 78px);
     2. three recession treatments on a Foco switch (0 = 065 today, A, B) — CSS only, keyed on :has();
     3. the D-19 chrome carried in, not judged here: drawer from the left (19d), one bottom snackbar
        with 10 s + ✕ when it carries an action (19b/19c), and the save bar pinned while dirty (19a).
   Run:  node .planning/sketches/066-estante-focus/build.js */
const fs = require('fs'), path = require('path');
const SRC = path.join(__dirname, '..', '065-admin-composition', 'index.html');
let html = fs.readFileSync(SRC, 'utf8');
const must = (s, a) => { if (!s.includes(a)) throw new Error('066 build: anchor not found: ' + a.slice(0, 60)); };

const CSS = `
/* ================= 066: estante focus (01.8.2 D-08) =================
   Recession never uses opacity. Measured: a shut row stays a live control (tapping it moves the
   focus), and its "65 juegos" line (muted #675C7D, 6.17:1) drops under 4.5:1 at opacity 0.88 —
   any fade you can see fails 1.4.3. So recession is a COLOUR step inside the palette:
   the name goes text -> muted (17.2 -> 6.2:1 light, 13.6 -> 6.9:1 dark), the icon and chevron go
   muted -> border tone is NOT allowed either (icons are 1.4.11 at 3:1), so they stay muted. */
  html[data-foco="a"] #device main:has(.grp .disclose[aria-expanded="true"]) .disclose[aria-expanded="false"] .gname,
  html[data-foco="b"] #device main:has(.grp .disclose[aria-expanded="true"]) .disclose[aria-expanded="false"] .gname { color: var(--color-text-muted); }
  html[data-foco="a"] #device main:has(.grp .disclose[aria-expanded="true"]) .disclose[aria-expanded="false"] .slot40,
  html[data-foco="b"] #device main:has(.grp .disclose[aria-expanded="true"]) .disclose[aria-expanded="false"] .slot40 { color: var(--color-text-muted); }
  html[data-foco="a"] #device main .disclose,
  html[data-foco="b"] #device main .disclose { transition: color var(--duration-base) var(--ease-out-soft); }
  html[data-foco] #device main .disclose .gname, html[data-foco] #device main .disclose .slot40 { transition: color var(--duration-base) var(--ease-out-soft); }
  /* B: the open estante also sits on the panel surface — full-bleed (.grp is inset 16px and its rows
     bleed −16, so the tint bleeds with two side shadows), so every content edge inside it
     (16px rows, the rail, the zone chips, the 76px note) stays where 065 measured it. */
  html[data-foco="b"] #device main .grp:has(> .glist > .disclose[aria-expanded="true"]),
  html[data-foco="b"] #device main .jsec.grp:has(.disclose[aria-expanded="true"]) { background: var(--color-surface); box-shadow: -16px 0 0 var(--color-surface), 16px 0 0 var(--color-surface); transition: background var(--duration-base) var(--ease-out-soft); }
  html[data-foco="b"] #device main .grp:has(> .glist > .disclose[aria-expanded="true"]) + .grp > .glist > .disclose::before { display: none; }
  html[data-foco="b"] #device main .grp:has(> .glist > .disclose[aria-expanded="true"]) > .glist > .disclose::before { display: none; }

/* ================= 066 round 2: master/detail ================= */
  /* a drill row points where it goes: right, never rotated like a disclosure */
  #device main .disclose.drill .chev { transform: none; }
  #device main .grp + .grp > .glist > .drill::before { display: block; left: 0; }
  /* the estante page has no header row, so its notes sit on the content edge (.grp is already inset 16px),
     not under the 76px text column a list row needs */
  #device main .est-detail .grp { margin: 0; }
  #device main .est-detail .grp .gnote, #device main .est-detail .grp .gnote.grail { margin-left: 0; padding-left: 0; }
  #device main .est-next { margin-top: 24px; }

/* ================= 066 carries 01.8.2 D-19 ================= */
  /* 19d: the drawer comes from the leading edge (the hamburger was already on the left). */
  #device .drawer { left: 0; right: auto; transform: translateX(-100%); }
  #device .drawer.open { transform: translateX(0); }
  /* 19c: one feedback component — the top toast is gone. */
  #device .toast { display: none !important; }
  /* 19b: a snackbar with an action carries a close glyph (A3, 44px hit box, pulled -12 to the edge). */
  #device .snack .snack-x { width: 44px; height: 44px; margin-right: -12px; display: inline-flex; align-items: center; justify-content: center; border: 0; background: none; color: var(--color-bg); border-radius: 50%; cursor: pointer; }
  #device .snack .snack-x svg { width: 18px; height: 18px; }
  #device .snack .snack-x[hidden] { display: none; }
  /* 19a: the save bar pins above the tab bar while dirty. Sticky cannot do it here — the bar's parent
     section ends at the bar, so a sticky box has nowhere to travel (measured: top 1495 of 1742 with
     sticky applied). The sketch shows a pinned twin while the in-page bar is off screen, which is the
     behaviour a sticky bar gives; the build decides the mechanism. */
  #device .ebar.inline.ebar-pin { position: absolute; left: 16px; right: 16px; bottom: 79px; z-index: 18; margin: 0;
    box-shadow: 0 4px 20px color-mix(in srgb, #2a1540 18%, transparent); }
  #device.kbd .ebar.inline.ebar-pin { bottom: calc(var(--kbh, 292px) + 12px); }
`;

const TOOLS = `<div>Estantes (066): <button data-e066="r2a" class="on">R2-A · lista → detalle ★</button> <button data-e066="r2b">R2-B · + Siguiente estante</button> <button data-e066="r1a">R1-A · en el lugar, texto atenuado</button> <button data-e066="r1b">R1-B · en el lugar, + panel</button></div>
    `;

/* the page-side script lives in page.js, so it can use template strings without escaping */
const JS = '\n' + fs.readFileSync(path.join(__dirname, 'page.js'), 'utf8');

must(html, '</style>'); must(html, '<div>Vista:'); must(html, '</script>'); must(html, 'function snack(');
html = html.replace(/<\/style>(?![\s\S]*<\/style>)/, CSS + '</style>');
html = html.replace('<div>Vista:', TOOLS + '<div>Vista:');
html = html.replace(/<\/script>(?![\s\S]*<\/script>)/, JS + '</script>');
html = html.replace(/<title>[^<]*<\/title>/, '<title>Sketch 066 — estantes, lista y detalle</title>');
fs.writeFileSync(path.join(__dirname, 'index.html'), html);
console.log('066 built', html.length, 'bytes');
