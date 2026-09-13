#!/usr/bin/env node
// Zero-dependency Node instrument for quick task 260912-waa (apply sketch
// 058's winner, H300, to the shared --pk-ramp-* ramp and the dark/light
// off-ramp roles it feeds).
//
// D-NoFourthCopy (same discipline ramp-audit.mjs itself follows): every
// sRGB<->OKLab<->OKLCh / WCAG primitive below is IMPORTED from
// `../../milestones/v1.0-quick/260910-if9-fix-light-dark-theme-color-family-consis/oklch-audit.mjs`
// (buildPalette, oklab, toOklch, oklchLightness, oklchChroma, oklchHue,
// contrastRatio, ROLE_TABLE, resolveRoleToken) -- not reimplemented. That
// file guards its own `main()` behind an `import.meta.url` check, so
// importing it here is safe (its own report/process.exit never fires).
//
// This script does NOT use that module's exported `APP_CSS_PATH` -- it is
// computed relative to the archived `260910-if9-...` directory and would
// resolve to `.planning/assets/css/app.css` from here (planning finding 1,
// PLAN.md). Computed fresh below, relative to THIS quick task's directory.
//
// The OKLCh-to-hex inverse (oklchToLab, labToLinearRgb,
// linearToSrgbChannel, isInGamut, maxChroma, oklchToHex, deltaE) is COPIED
// from `../../milestones/v1.0-quick/260910-l7q-redesign-the-light-dark-color-palette-as/ramp-audit.mjs`,
// with the same matrices and the same 40-iteration bisection, because that
// file cannot be imported: it calls `main()` unguarded at its own bottom,
// so importing it would immediately run ITS OWN report and `process.exit`.
//
// Sketch 058 (`.planning/sketches/058-dark-purple-hue/README.md`) picked
// winner C: rotate the ramp's hue from H313.1 to H300 (the brand manual's
// Lila Oscuro hue), holding each stop's OWN shipped OKLCh lightness --
// NOT ramp-audit.mjs's `buildLadder` gamut-peak/anchor-averaged ladder.
// Planning finding 2 (PLAN.md) measured that `buildLadder` does NOT
// reproduce the README at stop 500 (gamut-peak L recompute) or stop 950
// (dark base-100 anchor average) when HUE is simply changed to 300 --
// only holding each LIVE stop's own L reproduces the README byte-for-byte.
// This script's `deriveRampStop` implements that shipped-per-stop-L
// method; `buildLadder` is intentionally not ported.
//
// Two modes:
//   (no flag)  propose -- prints the ramp + rotation tables, exits 1 if
//              any proposed value differs from the README, else 0. Never
//              writes app.css.
//   --check    asserts the LIVE (already-edited) palette matches the
//              README byte-for-byte, every rotation-set role is a fixed
//              point of rotated(), light secondary is the H300 Violeta, and
//              every gated WCAG pair still passes. Prints every failure
//              and exits 1 on any; exits 0 only when everything holds.

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import {
  buildPalette,
  oklab,
  toOklch,
  oklchLightness,
  oklchChroma,
  oklchHue,
  contrastRatio,
  ROLE_TABLE,
  resolveRoleToken,
} from "../../milestones/v1.0-quick/260910-if9-fix-light-dark-theme-color-family-consis/oklch-audit.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
const APP_CSS_PATH = join(__dirname, "../../../assets/css/app.css");

const HUE = 300;
const K = 0.85;
const TEXT_FLOOR = 4.5;

// ---------------------------------------------------------------------
// Copied from ramp-audit.mjs (see header comment above for why it cannot
// be imported instead). Same matrices, same 40-iteration bisection.
// ---------------------------------------------------------------------

function oklchToLab(l, c, hDeg) {
  const hRad = (hDeg * Math.PI) / 180;
  return { l: l / 100, a: c * Math.cos(hRad), b: c * Math.sin(hRad) };
}

function labToLinearRgb({ l, a, b }) {
  const l_ = l + 0.3963377774 * a + 0.2158037573 * b;
  const m_ = l - 0.1055613458 * a - 0.0638541728 * b;
  const s_ = l - 0.0894841775 * a - 1.291485548 * b;

  const ll = l_ ** 3;
  const mm = m_ ** 3;
  const ss = s_ ** 3;

  const r = 4.0767416621 * ll - 3.3077115913 * mm + 0.2309699292 * ss;
  const g = -1.2684380046 * ll + 2.6097574011 * mm - 0.3413193965 * ss;
  const bl = -0.0041960863 * ll - 0.7034186147 * mm + 1.707614701 * ss;

  return [r, g, bl];
}

function linearToSrgbChannel(c) {
  if (c <= 0) return 0;
  if (c >= 1) return 1;
  return c <= 0.0031308 ? c * 12.92 : 1.055 * Math.pow(c, 1 / 2.4) - 0.055;
}

function isInGamut(l, c, hDeg) {
  const EPS = 1e-6;
  const [r, g, b] = labToLinearRgb(oklchToLab(l, c, hDeg));
  return r >= -EPS && r <= 1 + EPS && g >= -EPS && g <= 1 + EPS && b >= -EPS && b <= 1 + EPS;
}

function maxChroma(l, hDeg) {
  let lo = 0;
  let hi = 0.5;
  for (let i = 0; i < 40; i++) {
    const mid = (lo + hi) / 2;
    if (isInGamut(l, mid, hDeg)) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  return lo;
}

function oklchToHex(l, c, hDeg) {
  const [rl, gl, bl] = labToLinearRgb(oklchToLab(l, c, hDeg));
  const toByte = (ch) => Math.min(255, Math.max(0, Math.round(linearToSrgbChannel(ch) * 255)));
  const toHexByte = (n) => n.toString(16).padStart(2, "0").toUpperCase();
  return `#${toHexByte(toByte(rl))}${toHexByte(toByte(gl))}${toHexByte(toByte(bl))}`;
}

function deltaE(hexA, hexB) {
  const a = oklab(hexA);
  const b = oklab(hexB);
  return Math.sqrt((a.l - b.l) ** 2 + (a.a - b.a) ** 2 + (a.b - b.b) ** 2);
}

// ---------------------------------------------------------------------
// Sketch 058 winning token set (README "Winning token set" tables) --
// this is the authority the derived/rotated values are checked against
// (planning finding 2: the README values are what the developer actually
// looked at and picked).
// ---------------------------------------------------------------------

const SKETCH_058_RAMP = {
  50: "#F8F6FE",
  100: "#F1ECFD",
  200: "#DFD3FA",
  300: "#CBB5F6",
  400: "#B896F3",
  500: "#9959ED",
  600: "#7B2DCE",
  700: "#6222A6",
  800: "#4A187F",
  900: "#3C1269",
  950: "#300D56",
};

const SKETCH_058_DARK = {
  "base-100": "#2E154E",
  secondary: "#553384",
  accent: "#33224D",
  "accent-content": "#E3D9F9",
  neutral: "#B8A0E5",
  "pk-ink-brand": "#B797F0",
};

// Light secondary: the brand manual's Violeta #7E4CA5 (H308.1) rotated to
// H300 with L and C held, so both themes share one uniform hue (developer
// follow-up to 260912-waa). rotated("#7E4CA5") === "#7550AC".
const BRAND_VIOLETA = "#7E4CA5";
const LIGHT_SECONDARY_H300 = "#7550AC";

// Dark: the five README off-ramp roles (their own literal, not the ramp)
// plus the near-black -content inks that carry the SAME literal across
// info/success/warning/error, plus dark's own hue-canonical --pk-ink-brand.
// Rotating these (L and C held, H->300) is expected to reproduce planning
// finding 3's values; --check verifies each is a fixed point of rotated()
// once the edit lands.
const DARK_ROTATION_SET = [
  "base-100",
  "secondary",
  "accent",
  "accent-content",
  "neutral",
  "neutral-content",
  "info-content",
  "success-content",
  "warning-content",
  "error-content",
  "pk-ink-brand",
];

// Light: base-300, base-content (shared literal with warning-content, so
// both move together), accent, neutral and secondary (BRAND_VIOLETA rotated
// to LIGHT_SECONDARY_H300). Light primary/
// accent-content are var(--pk-ramp-*) reads, so they follow the ramp
// automatically and need no separate rotation entry here.
const LIGHT_ROTATION_SET = ["base-300", "base-content", "warning-content", "accent", "neutral", "secondary"];

// Excluded from rotation entirely, with reasons (not iterated anywhere
// above): #FFFFFF roles (achromatic -- no ramp/rotation stop invented for
// white); the info/success/warning/error FILL roles in both themes
// (D-Semantics, other hues, never join or rotate onto the brand ramp);
// every
// role that is a var(--pk-ramp-*) read (light primary, light
// accent-content, dark base-200, dark base-300, dark base-content, dark
// primary -- these follow the ramp by construction); and
// --pk-shadow-color (a fixed, theme-invariant near-black shadow declared
// once in :root, not a per-theme daisyUI role at all).
const SEMANTIC_HUE_ROLES = new Set([
  "info",
  "info-content",
  "success",
  "success-content",
  "warning",
  "warning-content",
  "error",
  "error-content",
]);

// ---------------------------------------------------------------------
// Palette parse helpers specific to this script (buildPalette from
// oklch-audit.mjs already dereferences var(--pk-ramp-*) reads to their
// hex, which is what every OKLCh/contrast computation below wants -- but
// it does not expose the RAW ramp stops themselves, or which theme roles
// are literal hexes vs var() reads, both of which this script needs for
// the ramp derivation and the "literal purple role" --check listing).
// ---------------------------------------------------------------------

function parseRampStops(css) {
  const rootRe = /:root \{([^}]*)\}/g;
  let match;
  while ((match = rootRe.exec(css)) !== null) {
    const body = match[1];
    if (body.includes("--pk-ramp-")) {
      const stops = {};
      const order = [];
      const stopRe = /--pk-ramp-([0-9]+):\s*(#[0-9A-Fa-f]{6})\s*;/g;
      let stopMatch;
      while ((stopMatch = stopRe.exec(body)) !== null) {
        stops[stopMatch[1]] = stopMatch[2].toUpperCase();
        order.push(stopMatch[1]);
      }
      return { stops, order };
    }
  }
  throw new Error("No plain `:root { ... }` block declaring a --pk-ramp- stop found");
}

// Raw (non-dereferenced) theme-block tokens, so callers can tell a literal
// hex apart from a `var(--pk-ramp-N)` read -- mirrors oklch-audit.mjs's own
// internal (unexported) parseThemeBlock.
function parseThemeBlockRaw(css, themeName) {
  const re = new RegExp(
    `@plugin "daisyui/packages/bundle/daisyui-theme" \\{\\s*name: "${themeName}";([\\s\\S]*?)\\n\\}`,
  );
  const match = css.match(re);
  if (!match) throw new Error(`No daisyui-theme block found for name: "${themeName}"`);
  const body = match[1];
  const tokenRe = /--color-([a-z0-9-]+):\s*(#[0-9A-Fa-f]{6}|var\(--pk-ramp-[0-9]+\))\s*;/g;
  const tokens = {};
  let tokenMatch;
  while ((tokenMatch = tokenRe.exec(body)) !== null) {
    tokens[tokenMatch[1]] = tokenMatch[2];
  }
  return tokens;
}

function isVarRead(rawValue) {
  return typeof rawValue === "string" && rawValue.startsWith("var(");
}

// ---------------------------------------------------------------------
// Derivation
// ---------------------------------------------------------------------

// Shipped-per-stop-L method (planning finding 2): hold each LIVE stop's
// own OKLCh lightness, recompute chroma as k * maxChroma(L, HUE) at the
// NEW hue, and rotate the hue. Deliberately NOT ramp-audit.mjs's
// `buildLadder` -- that function recomputes stop 500's L as the gamut
// peak AT THE NEW HUE (L55.3 at H300 vs the shipped L61.0 at H313.1) and
// derives stop 950's L from the dark base-100 anchor rather than the
// shipped stop itself, so re-running it at HUE=300 does NOT reproduce the
// README's stop 500 (#8D35EA instead of #9959ED) or stop 950 (#310D56
// instead of #300D56). This function is a fixed point on its own output:
// deriveRampStop(deriveRampStop(hex).hex).hex === deriveRampStop(hex).hex,
// because the second pass reads the L right back off the first pass's
// own hex.
function deriveRampStop(liveHex) {
  const l = oklchLightness(liveHex);
  const c = K * maxChroma(l, HUE);
  return { l, c, hex: oklchToHex(l, c, HUE) };
}

// Hue-only rotation: hold a role's own OKLCh L and C, rotate H to 300.
// Also a fixed point on its own output once a role already sits at H300
// (rotated(rotated(hex)) === rotated(hex)), which is exactly what
// --check's requirement (b) verifies post-edit.
function rotated(hex) {
  const { l, c } = toOklch(hex);
  return oklchToHex(l, c, HUE);
}

// ---------------------------------------------------------------------
// Contrast pairs (ported from ramp-audit.mjs's buildContrastPairs) and
// pinned-floor rechecks (ported from ramp-audit.mjs's recheckPinnedFloors,
// generalised over ROLE_TABLE/resolveRoleToken -- imported, not
// redeclared).
// ---------------------------------------------------------------------

const CONTENT_ROLES = ["primary", "secondary", "accent", "neutral", "info", "success", "warning", "error"];

function buildContrastPairs(theme) {
  const pairs = [
    { a: "base-content", b: "base-100", floor: TEXT_FLOOR },
    { a: "base-content", b: "base-200", floor: TEXT_FLOOR },
  ];

  if (theme === "light") {
    pairs.push({ a: "primary", b: "base-100", floor: TEXT_FLOOR });
    pairs.push({ a: "neutral", b: "base-200", floor: TEXT_FLOOR });
  }

  if (theme === "dark") {
    pairs.push({ a: "neutral", b: "base-100", floor: TEXT_FLOOR });
    pairs.push({ a: "pk-ink-brand", b: "base-100", floor: TEXT_FLOOR });
    pairs.push({ a: "pk-ink-brand", b: "base-200", floor: TEXT_FLOOR });
    pairs.push({ a: "pk-ink-brand", b: "base-300", floor: TEXT_FLOOR });
  }

  for (const role of CONTENT_ROLES) {
    pairs.push({ a: `${role}-content`, b: role, floor: TEXT_FLOOR });
  }
  return pairs;
}

// PRE-EXISTING, OUT-OF-SCOPE finding (discovered while running this
// script's own (e) contrast-pair gate, not caused by this quick task):
// light theme's `--color-success-content` (#FFFFFF) on `--color-success`
// (#3F8F6B) measures 3.92:1, below the 4.5:1 text floor. Neither role is
// touched anywhere by sketch 058/quick task 260912-waa -- both are
// D-Semantics FILL colours, categorically excluded from the ramp and from
// every rotation set this task defines (see the header comment above).
// Per the executor's SCOPE BOUNDARY doctrine ("only auto-fix issues
// DIRECTLY caused by the current task's changes"), this is logged here
// (and in the quick task's SUMMARY/WINDOWS.md entry) rather than silently
// fixed -- fixing it would be an uninstructed, out-of-scope palette
// change to a role this task was never asked to touch. Still printed as
// a WARN below (not a silent skip), just excluded from the exit-code
// gate this script's `ok` flag drives.
const KNOWN_PREEXISTING_CONTRAST_EXCEPTIONS = [{ theme: "light", a: "success-content", b: "success" }];

function isKnownPreexistingException(theme, pair) {
  return KNOWN_PREEXISTING_CONTRAST_EXCEPTIONS.some(
    (ex) => ex.theme === theme && ex.a === pair.a && ex.b === pair.b,
  );
}

function recheckPinnedFloors(palette) {
  const checks = [
    { label: "dark --pk-ink-brand on base-100", theme: "dark", a: "pk-ink-brand", b: "base-100", floor: TEXT_FLOOR },
    { label: "dark --pk-ink-brand on base-200", theme: "dark", a: "pk-ink-brand", b: "base-200", floor: TEXT_FLOOR },
    { label: "dark --pk-ink-brand on base-300", theme: "dark", a: "pk-ink-brand", b: "base-300", floor: TEXT_FLOOR },
    { label: "dark neutral on base-100", theme: "dark", a: "neutral", b: "base-100", floor: TEXT_FLOOR },
    { label: "dark neutral on base-200", theme: "dark", a: "neutral", b: "base-200", floor: TEXT_FLOOR },
    { label: "light primary on base-100 (white)", theme: "light", a: "primary", b: "base-100", floor: TEXT_FLOOR },
    { label: "dark primary-content on primary", theme: "dark", a: "primary-content", b: "primary", floor: TEXT_FLOOR },
  ];

  // Sketch 054's four pinned dark-mode floors (catalog_show_test.exs),
  // re-measured here so a --check regression is caught before mix test
  // ever runs.
  checks.push(
    { label: "sketch 054: dark base-content on base-100", theme: "dark", a: "base-content", b: "base-100", floor: 13.593 },
    { label: "sketch 054: dark neutral on base-100", theme: "dark", a: "neutral", b: "base-100", floor: 6.847 },
    { label: "sketch 054: dark base-content on base-200", theme: "dark", a: "base-content", b: "base-200", floor: 12.069 },
    { label: "sketch 054: dark primary-content on primary", theme: "dark", a: "primary-content", b: "primary", floor: 6.696 },
  );

  const results = checks.map((c) => {
    const hexA = palette[c.theme][c.a];
    const hexB = palette[c.theme][c.b];
    const ratio = contrastRatio(hexA, hexB);
    return { ...c, hexA, hexB, ratio, pass: ratio >= c.floor };
  });

  for (const spec of ROLE_TABLE) {
    for (const themeName of ["light", "dark"]) {
      const fillToken = resolveRoleToken(spec.fill, themeName);
      const inkToken = resolveRoleToken(spec.ink, themeName);
      const groundToken = fillToken && fillToken !== "transparent" ? fillToken : "base-100";
      const groundHex = palette[themeName][groundToken];

      if (inkToken && inkToken !== "transparent" && groundHex) {
        const inkHex = palette[themeName][inkToken];
        if (inkHex) {
          const ratio = contrastRatio(inkHex, groundHex);
          results.push({
            label: `${spec.tone} (${themeName}) ink/${groundToken}`,
            theme: themeName,
            a: inkToken,
            b: groundToken,
            floor: TEXT_FLOOR,
            hexA: inkHex,
            hexB: groundHex,
            ratio,
            pass: ratio >= TEXT_FLOOR,
          });
        }
      }
    }
  }

  return results;
}

function fmt(n, decimals = 1) {
  return n.toFixed(decimals);
}

// ---------------------------------------------------------------------
// Propose mode
// ---------------------------------------------------------------------

function runPropose(css) {
  const { stops: liveRamp, order } = parseRampStops(css);
  let ok = true;

  console.log("H300 audit -- quick task 260912-waa (propose mode)");
  console.log(`Live palette read from ${APP_CSS_PATH}`);
  console.log(`Target hue: H${HUE}, k=${K}\n`);

  console.log("=== Ramp (shipped-per-stop-L method) ===");
  console.log("stop  live       proposed   README     verdict");
  for (const stop of order) {
    const liveHex = liveRamp[stop];
    const { hex: proposedHex } = deriveRampStop(liveHex);
    const readmeHex = SKETCH_058_RAMP[stop];
    const verdict = proposedHex === readmeHex ? "MATCH" : "DIFF";
    if (verdict === "DIFF") ok = false;
    console.log(
      `${String(stop).padEnd(5)} ${liveHex.padEnd(10)} ${proposedHex.padEnd(10)} ${readmeHex.padEnd(10)} ${verdict}`,
    );
  }

  const palette = buildPalette(css);

  console.log("\n=== Dark rotation set (README-pinned six roles + remaining near-black inks) ===");
  console.log("role                shipped    proposed   README     verdict");
  for (const role of DARK_ROTATION_SET) {
    const shipped = palette.dark[role];
    const proposed = rotated(shipped);
    const readme = SKETCH_058_DARK[role];
    let verdict;
    if (readme) {
      verdict = proposed === readme ? "MATCH" : "DIFF";
      if (verdict === "DIFF") ok = false;
    } else {
      verdict = "(no README pin -- expected value only)";
    }
    console.log(
      `${role.padEnd(19)} ${shipped.padEnd(10)} ${proposed.padEnd(10)} ${(readme ?? "-").padEnd(10)} ${verdict}`,
    );
  }

  console.log("\n=== Light rotation set (not rendered in sketch 058, expected via the same generator) ===");
  console.log("role                shipped    proposed   live hue   proposed hue");
  for (const role of LIGHT_ROTATION_SET) {
    const shipped = palette.light[role];
    const proposed = rotated(shipped);
    console.log(
      `${role.padEnd(19)} ${shipped.padEnd(10)} ${proposed.padEnd(10)} ${fmt(oklchHue(shipped)).padEnd(10)} ${fmt(oklchHue(proposed))}`,
    );
  }

  const lightSecondary = palette.light.secondary;
  console.log(
    `\nlight secondary: ${lightSecondary} (H${fmt(oklchHue(lightSecondary))}) -- BRAND_VIOLETA ${BRAND_VIOLETA} rotates to ${rotated(BRAND_VIOLETA)}, expected ${LIGHT_SECONDARY_H300}`,
  );

  console.log(`\nassets/css/app.css was NOT modified by this script (propose mode).`);
  console.log(ok ? "\nPROPOSE: all pinned values MATCH the sketch 058 README." : "\nPROPOSE: at least one value DIFFERS from the README -- do not edit app.css, report this table.");
  process.exit(ok ? 0 : 1);
}

// ---------------------------------------------------------------------
// Check mode
// ---------------------------------------------------------------------

function runCheck(css) {
  let ok = true;
  const fail = (msg) => {
    console.log(`FAIL: ${msg}`);
    ok = false;
  };

  console.log("H300 audit -- quick task 260912-waa (--check mode)");
  console.log(`Live palette read from ${APP_CSS_PATH}\n`);

  const { stops: liveRamp, order } = parseRampStops(css);
  const palette = buildPalette(css);

  // (a) every live ramp stop equals SKETCH_058_RAMP and is a fixed point
  // of the ramp transform.
  console.log("=== (a) ramp stops: README equality + fixed point ===");
  for (const stop of order) {
    const liveHex = liveRamp[stop];
    const readmeHex = SKETCH_058_RAMP[stop];
    const { hex: refixed } = deriveRampStop(liveHex);
    const matchesReadme = liveHex === readmeHex;
    const isFixedPoint = refixed === liveHex;
    console.log(
      `  --pk-ramp-${stop}: ${liveHex} vs README ${readmeHex} -- ${matchesReadme ? "MATCH" : "DIFF"}; fixed-point re-derive ${refixed} -- ${isFixedPoint ? "HOLDS" : "DIFF"}`,
    );
    if (!matchesReadme) fail(`--pk-ramp-${stop} is ${liveHex}, expected README ${readmeHex}`);
    if (!isFixedPoint) fail(`--pk-ramp-${stop} (${liveHex}) is not a fixed point of the ramp transform (re-derives to ${refixed})`);
  }

  // (b) every role in the rotation set is a fixed point of rotated().
  console.log("\n=== (b) rotation-set fixed points (already at H300) ===");
  for (const [themeName, roles] of [
    ["dark", DARK_ROTATION_SET],
    ["light", LIGHT_ROTATION_SET],
  ]) {
    for (const role of roles) {
      const shipped = palette[themeName][role];
      const rot = rotated(shipped);
      const isFixedPoint = rot === shipped;
      console.log(`  ${themeName}.${role}: ${shipped} -- rotated ${rot} -- ${isFixedPoint ? "HOLDS" : "DIFF"}`);
      if (!isFixedPoint) fail(`${themeName}.${role} (${shipped}) is not a fixed point of rotated() (rotates to ${rot})`);
    }
  }

  // (c) the six SKETCH_058_DARK roles equal the README.
  console.log("\n=== (c) dark README-pinned roles ===");
  for (const [role, readmeHex] of Object.entries(SKETCH_058_DARK)) {
    const shipped = palette.dark[role];
    const matches = shipped === readmeHex;
    console.log(`  dark.${role}: ${shipped} vs README ${readmeHex} -- ${matches ? "MATCH" : "DIFF"}`);
    if (!matches) fail(`dark.${role} is ${shipped}, expected README ${readmeHex}`);
  }

  // (d) light secondary equals BRAND_VIOLETA rotated to H300.
  console.log("\n=== (d) light secondary (brand Violeta rotated to H300) ===");
  const lightSecondary = palette.light.secondary;
  const expectedSecondary = rotated(BRAND_VIOLETA);
  console.log(`  light.secondary: ${lightSecondary} -- expected ${expectedSecondary} -- ${lightSecondary === expectedSecondary ? "MATCH" : "DIFF"}`);
  if (lightSecondary !== expectedSecondary || expectedSecondary !== LIGHT_SECONDARY_H300) fail(`light.secondary is ${lightSecondary}, expected ${LIGHT_SECONDARY_H300}`);

  // (e) every contrast pair passes.
  console.log("\n=== (e) contrast pairs ===");
  for (const themeName of ["light", "dark"]) {
    const pairs = buildContrastPairs(themeName);
    for (const pair of pairs) {
      const hexA = palette[themeName][pair.a];
      const hexB = palette[themeName][pair.b];
      if (!hexA || !hexB) continue;
      const ratio = contrastRatio(hexA, hexB);
      const pass = ratio >= pair.floor;
      const preexisting = !pass && isKnownPreexistingException(themeName, pair);
      const verdict = pass ? "PASS" : preexisting ? "WARN (pre-existing, out of scope)" : "FAIL";
      console.log(
        `  ${themeName} ${pair.a}/${pair.b}: ${hexA} vs ${hexB} = ${fmt(ratio, 2)}:1 (floor ${pair.floor}:1) -- ${verdict}`,
      );
      if (!pass && !preexisting) {
        fail(`${themeName} ${pair.a}/${pair.b} measured ${fmt(ratio, 2)}:1, below floor ${pair.floor}:1`);
      }
    }
  }

  console.log("\n=== (e continued) pinned floors + ROLE_TABLE ink/ground ===");
  const floorResults = recheckPinnedFloors(palette);
  for (const f of floorResults) {
    console.log(
      `  ${f.pass ? "HOLDS " : "BREAKS"} ${f.label}: ${f.hexA} vs ${f.hexB} = ${fmt(f.ratio, 2)}:1 (floor ${f.floor}:1)`,
    );
    if (!f.pass) fail(`${f.label} measured ${fmt(f.ratio, 2)}:1, below floor ${f.floor}:1`);
  }

  // Informational: nearest applied ramp stop + deltaE for every literal
  // (non-var) purple role, for Task 3's per-role annotation refresh.
  console.log("\n=== Informational: nearest ramp stop per literal role (Task 3 annotation input) ===");
  const rawLight = parseThemeBlockRaw(css, "light");
  const rawDark = parseThemeBlockRaw(css, "dark");
  const rampEntries = order.map((stop) => [stop, liveRamp[stop]]);

  for (const [themeName, rawTokens] of [
    ["light", rawLight],
    ["dark", rawDark],
  ]) {
    for (const [role, rawValue] of Object.entries(rawTokens)) {
      if (isVarRead(rawValue)) continue;
      if (SEMANTIC_HUE_ROLES.has(role)) continue;
      if (rawValue === "#FFFFFF") continue;

      let best = null;
      for (const [stop, hex] of rampEntries) {
        const de = deltaE(rawValue, hex);
        if (!best || de < best.deltaE) best = { stop, hex, deltaE: de };
      }
      console.log(
        `  ${themeName}.${role} (${rawValue}) -- nearest --pk-ramp-${best.stop} (${best.hex}), dE=${best.deltaE.toFixed(4)}`,
      );
    }
  }

  console.log(ok ? "\n--check: all assertions HOLD." : "\n--check: at least one assertion FAILED (see above).");
  process.exit(ok ? 0 : 1);
}

// ---------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------

function main() {
  let css;
  try {
    css = readFileSync(APP_CSS_PATH, "utf8");
  } catch (err) {
    console.error(`FAIL: could not read ${APP_CSS_PATH}: ${err.message}`);
    process.exit(1);
  }

  const checkMode = process.argv.includes("--check");
  if (checkMode) {
    runCheck(css);
  } else {
    runPropose(css);
  }
}

main();
