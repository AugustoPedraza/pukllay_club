/* Sketch 067 — read an estante (01.8.2 D-22, workflow 1 of 7).
   Takes 066's built page (065 + master/detail + D-19 chrome) VERBATIM and replaces only what is inside the
   Estantes list and the estante page, on a fixture of the club's real shape: 9 horizontal estantes,
   46–50 boxes each, the 434 real published game names.
   Run:  node .planning/sketches/067-estante-read/build.js */
const fs = require('fs'), path = require('path');
let html = fs.readFileSync(path.join(__dirname, '..', '066-estante-focus', 'index.html'), 'utf8');
const must = a => { if (!html.includes(a)) throw new Error('067 build: anchor not found: ' + a.slice(0, 60)); };
const CSS = fs.readFileSync(path.join(__dirname, 'page.css'), 'utf8');
const JS = fs.readFileSync(path.join(__dirname, 'games.js'), 'utf8') + '\n' + fs.readFileSync(path.join(__dirname, 'page.js'), 'utf8');
const TOOLS = `<div>Leer (067): <button data-r067="a">A · Lista numerada</button> <button data-r067="b">B · Grilla</button> <button data-r067="c" class="on">C · Riel con portadas ★</button></div>
    `;
must('</style>'); must('<div>Estantes (066):'); must('</script>');
html = html.replace(/<\/style>(?![\s\S]*<\/style>)/, CSS + '</style>');
html = html.replace('<div>Estantes (066):', TOOLS + '<div style="display:none">Estantes (066):');
html = html.replace(/<\/script>(?![\s\S]*<\/script>)/, JS + '</script>');
html = html.replace(/<title>[^<]*<\/title>/, '<title>Sketch 067 — leer un estante</title>');
fs.writeFileSync(path.join(__dirname, 'index.html'), html);
console.log('067 built', html.length, 'bytes');
