#!/usr/bin/env node
// Zero-dependency Node oracle for quick task 260910-if9 (light/dark chip &
// label colour-family audit).
//
// Reads the real palette straight out of `assets/css/app.css` (the two
// `@plugin "daisyui-theme"` blocks plus the `--pk-ink-brand` token declared
// in the plain `:root` block and in `:root[data-theme="dark"]`) — no
// hardcoded palette copy in this script, so it stays true if the palette
// ever moves. Converts every resolved token to OKLCh using the exact same
// sRGB->linear->OKLab->OKLCh math already vendored in
// `test/pukllay_club_web/live/catalog_show_test.exs` (`oklab/1`,
// `oklch_chroma/1`, `oklch_hue/1`) and in
// `.planning/sketches/054-dark-mode-color-composition/contrast-check.mjs`
// (WCAG relative-luminance/contrast), so a number this script prints and a
// number the ExUnit tripwires assert can never quietly disagree about the
// underlying formula.
//
// Then applies a hardcoded ROLE_TABLE — the one place a token NAME is
// written down; every VALUE still comes from the parse above — naming which
// token fills each of a pill/chip tone's three roles (fill, border, ink),
// and prints, per tone per theme: each populated role's hex/L/C/H, the
// tone's intra-theme max-hue-spread and a PASS/FAIL against a named
// threshold constant, plus a cross-theme hue-delta/chroma-ratio comparison
// for fill and ink. A final SUMMARY section lists every intra-theme failure
// and every cross-theme chroma ratio over 3x.
//
// Exits 0 always — this is a measurement instrument, not yet a gate. Task 3
// of the 260910-if9 plan turns the developer-confirmed constraints into
// ExUnit tripwires; this script stays exit-0 so it remains usable by hand
// for exploring a candidate palette before it is written into app.css.

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const APP_CSS_PATH = join(__dirname, "../../../assets/css/app.css");

// Proposal, not a settled rule (plan `<measured_baseline>`, Task 1 step 4):
// light's own worst intra-tone spread is `.pk-pill-accent` at 9.8 degrees,
// so 8 degrees is a starting threshold for Task 2 to confirm or revise, not
// a value this script or the developer should treat as already decided.
const HUE_FAMILY_THRESHOLD_DEG = 8;
const CROSS_THEME_CHROMA_RATIO_FLAG = 3;

// ---------------------------------------------------------------------
// sRGB -> OKLCh / WCAG relative luminance
// (mirrors test/pukllay_club_web/live/catalog_show_test.exs's
// parse_rgb/1, srgb_channel_to_linear/1, oklab/1, oklch_chroma/1,
// oklch_hue/1, relative_luminance/1 and contrast_ratio/2 exactly)
// ---------------------------------------------------------------------

function hexToRgb(hex) {
  const h = hex.trim().replace("#", "");
  return [0, 2, 4].map((i) => parseInt(h.substr(i, 2), 16));
}

function srgbChannelToLinear(channel) {
  const c = channel / 255;
  return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
}

function relativeLuminance(hex) {
  const [r, g, b] = hexToRgb(hex);
  const [rl, gl, bl] = [r, g, b].map(srgbChannelToLinear);
  return 0.2126 * rl + 0.7152 * gl + 0.0722 * bl;
}

function contrastRatio(hexA, hexB) {
  const lA = relativeLuminance(hexA);
  const lB = relativeLuminance(hexB);
  const lighter = Math.max(lA, lB);
  const darker = Math.min(lA, lB);
  return (lighter + 0.05) / (darker + 0.05);
}

function oklab(hex) {
  const [r, g, b] = hexToRgb(hex);
  const [rl, gl, bl] = [r, g, b].map(srgbChannelToLinear);

  const l = 0.4122214708 * rl + 0.5363325363 * gl + 0.0514459929 * bl;
  const m = 0.2119034982 * rl + 0.6806995451 * gl + 0.1073969566 * bl;
  const s = 0.0883024619 * rl + 0.2817188376 * gl + 0.6299787005 * bl;

  const cbrt = (v) => (v < 0 ? -Math.pow(-v, 1 / 3) : Math.pow(v, 1 / 3));
  const l_ = cbrt(l);
  const m_ = cbrt(m);
  const s_ = cbrt(s);

  const labL = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_;
  const labA = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_;
  const labB = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_;

  return { l: labL, a: labA, b: labB };
}

function oklchLightness(hex) {
  return oklab(hex).l * 100;
}

function oklchChroma(hex) {
  const { a, b } = oklab(hex);
  return Math.sqrt(a * a + b * b);
}

function oklchHue(hex) {
  const { a, b } = oklab(hex);
  const degrees = (Math.atan2(b, a) * 180) / Math.PI;
  return degrees < 0 ? degrees + 360 : degrees;
}

function toOklch(hex) {
  return {
    hex: hex.toUpperCase(),
    l: oklchLightness(hex),
    c: oklchChroma(hex),
    h: oklchHue(hex),
  };
}

// ---------------------------------------------------------------------
// Palette parse (assets/css/app.css is the single upstream source)
// ---------------------------------------------------------------------

function parseThemeBlock(css, themeName) {
  const re = new RegExp(
    `@plugin "daisyui/packages/bundle/daisyui-theme" \\{\\s*name: "${themeName}";([\\s\\S]*?)\\n\\}`,
  );
  const match = css.match(re);
  if (!match) {
    throw new Error(`No daisyui-theme block found for name: "${themeName}"`);
  }
  const body = match[1];
  const tokenRe = /--color-([a-z0-9-]+):\s*(#[0-9A-Fa-f]{6})\s*;/g;
  const tokens = {};
  let tokenMatch;
  while ((tokenMatch = tokenRe.exec(body)) !== null) {
    tokens[tokenMatch[1]] = tokenMatch[2].toUpperCase();
  }
  return tokens;
}

// Plain `:root { ... }` — there are two in app.css; this one is
// distinguished by containing the `--pk-ink-brand` declaration.
function parsePlainRootPkInkBrand(css) {
  const rootRe = /:root \{([^}]*)\}/g;
  let match;
  while ((match = rootRe.exec(css)) !== null) {
    const body = match[1];
    if (body.includes("--pk-ink-brand:")) {
      const valueMatch = body.match(/--pk-ink-brand:\s*([^;]+);/);
      if (!valueMatch) throw new Error("Found --pk-ink-brand declaration but could not parse its value");
      return valueMatch[1].trim();
    }
  }
  throw new Error("No plain `:root { ... }` block declaring --pk-ink-brand found");
}

function parseDarkRootPkInkBrand(css) {
  const match = css.match(/:root\[data-theme="dark"\]\s*\{([^}]*)\}/);
  if (!match) throw new Error('No `:root[data-theme="dark"] { ... }` block found');
  const valueMatch = match[1].match(/--pk-ink-brand:\s*(#[0-9A-Fa-f]{6})\s*;/);
  if (!valueMatch) throw new Error('No `--pk-ink-brand` hex declaration found in `:root[data-theme="dark"]`');
  return valueMatch[1].toUpperCase();
}

function buildPalette(css) {
  const light = parseThemeBlock(css, "light");
  const dark = parseThemeBlock(css, "dark");

  // Resolve light's --pk-ink-brand, which is a `var(--color-primary)` READ
  // (see app.css's own provenance comment), one level against light's
  // theme block. Dark's is already a concrete hex.
  const lightInkBrandRaw = parsePlainRootPkInkBrand(css);
  const lightPkInkBrand = lightInkBrandRaw.startsWith("var(")
    ? light[lightInkBrandRaw.match(/var\(--color-([a-z0-9-]+)\)/)[1]]
    : lightInkBrandRaw.toUpperCase();
  const darkPkInkBrand = parseDarkRootPkInkBrand(css);

  return {
    light: { ...light, "pk-ink-brand": lightPkInkBrand },
    dark: { ...dark, "pk-ink-brand": darkPkInkBrand },
  };
}

// ---------------------------------------------------------------------
// ROLE_TABLE — the one place a token NAME is written down (plan Task 1
// step 3). "transparent" roles have no token to resolve and are excluded
// from the OKLCh table / intra-theme spread; null roles are simply absent
// for that tone (e.g. .pk-pill-interactive:hover has no fill role).
// ---------------------------------------------------------------------

const ROLE_TABLE = [
  { tone: ".pk-pill-neutral", fill: "base-200", border: "base-300", ink: "neutral" },
  { tone: ".pk-pill-outline", fill: "transparent", border: "base-300", ink: "neutral" },
  { tone: ".pk-pill-accent", fill: "accent", border: "accent", ink: "accent-content" },
  {
    tone: ".pk-pill-tag",
    fill: "transparent",
    border: "transparent",
    ink: { light: "primary", dark: "pk-ink-brand" },
  },
  { tone: ".pk-pill-selected", fill: "primary", border: "primary", ink: "primary-content" },
  { tone: ".pk-pill-interactive:hover", fill: null, border: "pk-ink-brand", ink: "pk-ink-brand" },
  { tone: ".pk-chip", fill: "transparent", border: "base-300", ink: "neutral" },
  { tone: ".pk-chip.is-active", fill: "accent", border: "primary", ink: "accent-content" },
];

function resolveRoleToken(roleSpec, themeName) {
  if (roleSpec === null || roleSpec === "transparent") return roleSpec;
  if (typeof roleSpec === "object") return roleSpec[themeName];
  return roleSpec;
}

function hueDelta(hA, hB) {
  const diff = Math.abs(hA - hB) % 360;
  return diff > 180 ? 360 - diff : diff;
}

// ---------------------------------------------------------------------
// Measure
// ---------------------------------------------------------------------

function measureTone(spec, palette) {
  const perTheme = {};
  for (const themeName of ["light", "dark"]) {
    const tokens = palette[themeName];
    const roles = {};
    for (const roleName of ["fill", "border", "ink"]) {
      const tokenName = resolveRoleToken(spec[roleName], themeName);
      if (tokenName === null || tokenName === "transparent") {
        roles[roleName] = { token: tokenName, populated: false };
        continue;
      }
      const hex = tokens[tokenName];
      if (!hex) {
        throw new Error(`Tone "${spec.tone}" (${themeName}) role "${roleName}" points at unknown token "${tokenName}"`);
      }
      roles[roleName] = { token: tokenName, populated: true, ...toOklch(hex) };
    }

    const populatedHues = Object.values(roles)
      .filter((r) => r.populated)
      .map((r) => r.h);
    let maxSpread = 0;
    for (let i = 0; i < populatedHues.length; i++) {
      for (let j = i + 1; j < populatedHues.length; j++) {
        maxSpread = Math.max(maxSpread, hueDelta(populatedHues[i], populatedHues[j]));
      }
    }
    const pass = maxSpread <= HUE_FAMILY_THRESHOLD_DEG;

    perTheme[themeName] = { roles, maxSpread, pass };
  }

  // Cross-theme: fill and ink hue delta + chroma ratio (light vs dark).
  const crossTheme = {};
  for (const roleName of ["fill", "ink"]) {
    const lightRole = perTheme.light.roles[roleName];
    const darkRole = perTheme.dark.roles[roleName];
    if (!lightRole.populated || !darkRole.populated) {
      crossTheme[roleName] = null;
      continue;
    }
    const hDelta = hueDelta(lightRole.h, darkRole.h);
    const cRatio = darkRole.c === 0 ? Infinity : lightRole.c === 0 ? 0 : Math.max(lightRole.c, darkRole.c) / Math.min(lightRole.c, darkRole.c);
    crossTheme[roleName] = { hueDelta: hDelta, chromaRatio: cRatio, lightC: lightRole.c, darkC: darkRole.c };
  }

  return { tone: spec.tone, perTheme, crossTheme };
}

function fmt(n, decimals = 1) {
  return n.toFixed(decimals);
}

function printToneTable(measurements) {
  for (const m of measurements) {
    console.log(`\n${m.tone}`);
    for (const themeName of ["light", "dark"]) {
      const t = m.perTheme[themeName];
      console.log(`  ${themeName}:`);
      for (const roleName of ["fill", "border", "ink"]) {
        const r = t.roles[roleName];
        if (!r.populated) {
          console.log(`    ${roleName.padEnd(7)} ${String(r.token).padEnd(9)} (not populated)`);
          continue;
        }
        console.log(
          `    ${roleName.padEnd(7)} ${r.token.padEnd(9)} ${r.hex.padEnd(8)} L${fmt(r.l)} C${fmt(r.c, 3)} H${fmt(r.h)}`,
        );
      }
      console.log(
        `    intra-theme max hue spread: ${fmt(t.maxSpread)} deg -- ${t.pass ? "PASS" : "FAIL"} (threshold ${HUE_FAMILY_THRESHOLD_DEG} deg)`,
      );
    }
    console.log(`  cross-theme (light vs dark):`);
    for (const roleName of ["fill", "ink"]) {
      const c = m.crossTheme[roleName];
      if (!c) {
        console.log(`    ${roleName}: N/A (not populated in one or both themes)`);
        continue;
      }
      console.log(
        `    ${roleName.padEnd(7)} hue delta ${fmt(c.hueDelta)} deg, chroma ratio ${fmt(c.chromaRatio, 2)}x (light C${fmt(c.lightC, 3)} / dark C${fmt(c.darkC, 3)})`,
      );
    }
  }
}

function printSummary(measurements) {
  console.log("\n=== SUMMARY ===");

  const intraFailures = [];
  for (const m of measurements) {
    for (const themeName of ["light", "dark"]) {
      if (!m.perTheme[themeName].pass) {
        intraFailures.push(`${m.tone} (${themeName}): ${fmt(m.perTheme[themeName].maxSpread)} deg spread`);
      }
    }
  }

  const chromaFlags = [];
  for (const m of measurements) {
    for (const roleName of ["fill", "ink"]) {
      const c = m.crossTheme[roleName];
      if (c && c.chromaRatio > CROSS_THEME_CHROMA_RATIO_FLAG) {
        chromaFlags.push(`${m.tone} ${roleName}: ${fmt(c.chromaRatio, 2)}x cross-theme chroma ratio`);
      }
    }
  }

  console.log(`\nIntra-theme hue-family failures (> ${HUE_FAMILY_THRESHOLD_DEG} deg spread):`);
  if (intraFailures.length === 0) {
    console.log("  none");
  } else {
    for (const f of intraFailures) console.log(`  - ${f}`);
  }

  console.log(`\nCross-theme chroma ratio flags (> ${CROSS_THEME_CHROMA_RATIO_FLAG}x):`);
  if (chromaFlags.length === 0) {
    console.log("  none");
  } else {
    for (const f of chromaFlags) console.log(`  - ${f}`);
  }
}

function main() {
  let css;
  try {
    css = readFileSync(APP_CSS_PATH, "utf8");
  } catch (err) {
    console.error(`FAIL: could not read ${APP_CSS_PATH}: ${err.message}`);
    process.exit(1);
  }

  let palette;
  try {
    palette = buildPalette(css);
  } catch (err) {
    console.error(`FAIL: could not parse palette: ${err.message}`);
    process.exit(1);
  }

  const measurements = ROLE_TABLE.map((spec) => measureTone(spec, palette));

  console.log("OKLCh audit -- quick task 260910-if9");
  console.log(`Threshold (proposal, Task 2 confirms): ${HUE_FAMILY_THRESHOLD_DEG} deg intra-theme hue spread`);
  printToneTable(measurements);
  printSummary(measurements);

  process.exit(0);
}

main();
