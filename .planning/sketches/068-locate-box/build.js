/* Sketch 068 — locate a box (01.8.2 D-22; the most frequent real-world job).
   "Where does this box go back?" and "where is this game, to pick it up?" — one answer: which estante,
   which position, between which neighbours. Takes 067's built page (065 + 066 master/detail + D-19 chrome +
   the 9 real estantes with covers) VERBATIM and adds search on the Estantes list, the answer, and the
   selected box on the estante page.
   Run:  node .planning/sketches/068-locate-box/build.js */
const fs = require('fs'), path = require('path');
let html = fs.readFileSync(path.join(__dirname, '..', '067-estante-read', 'index.html'), 'utf8');
const must = a => { if (!html.includes(a)) throw new Error('068 build: anchor not found: ' + a.slice(0, 60)); };
const CSS = fs.readFileSync(path.join(__dirname, 'page.css'), 'utf8');
const JS = fs.readFileSync(path.join(__dirname, 'page.js'), 'utf8');
const TOOLS = `<div>Ubicar (068): <button data-r068="a" class="on">A · La fila responde</button> <button data-r068="b">B · Fila + vecinos</button></div>
    `;
must('</style>'); must('<div>Leer (067):'); must('</script>');
html = html.replace(/<\/style>(?![\s\S]*<\/style>)/, CSS + '</style>');
html = html.replace('<div>Leer (067):', TOOLS + '<div style="display:none">Leer (067):');
html = html.replace(/<\/script>(?![\s\S]*<\/script>)/, JS + '</script>');
html = html.replace(/<title>[^<]*<\/title>/, '<title>Sketch 068 — ubicar una caja</title>');
fs.writeFileSync(path.join(__dirname, 'index.html'), html);
console.log('068 built', html.length, 'bytes');
