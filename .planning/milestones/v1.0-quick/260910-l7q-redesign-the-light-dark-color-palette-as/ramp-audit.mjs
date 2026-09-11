#!/usr/bin/env node
// Zero-dependency Node instrument for quick task 260910-l7q (shared OKLCh
// ramp). Generates TWO candidate 11-stop ramps at the brand hue (H313.1)
// from the LIVE palette in `assets/css/app.css` -- never a hardcoded
// palette copy -- and audits, role by role across both themes, which
// roles the contrast budget lets JOIN the ramp and which must stay
// OFF-RAMP, per D-Reuse's "report both sets" requirement.
//
// FLAT: every stop at C = k . maxC(L, H313.1) for a single safety factor k
// (swept across 0.85 / 0.87 / 0.90). Smoothest envelope; costs the most
// already-approved anchor values.
//
// ANCHORED: the flat-k=0.85 baseline, except every stop that lands on an
// already-shipped, developer-approved value holds THAT value's own L and C
// (clamped to the sRGB gamut at H313.1) and only rotates its hue. Fewest
// approved colours disturbed -- D-Ramp's "hand-nudged only at anchor
// stops" clause used to its full extent.
//
// D-NoFourthCopy: every piece of sRGB<->OKLab<->OKLCh / WCAG math below is
// IMPORTED from `../260910-if9-.../oklch-audit.mjs`, not reimplemented --
// that file is this quick task's OWN template (per Task 2's read_first)
// and is now guarded (`import.meta.url` check at its own bottom) so
// importing it here never triggers ITS report or its own `process.exit`.
// The only genuinely new maths lives in this file: an OKLCh-to-linear-sRGB
// inverse, an in-gamut predicate, a `maxC(L, H)` bisection on that
// predicate, an OKLCh-to-hex, an OKLab ΔE (plain Euclidean distance), and
// the L-ladder/anchor derivation itself.
//
// Exits 0 always -- a measurement instrument, not yet a gate (Task 5 turns
// the developer-confirmed pick into ExUnit tripwires). Does not modify
// `assets/css/app.css`.

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import {
  APP_CSS_PATH,
  buildPalette,
  oklab,
  oklchLightness,
  oklchChroma,
  contrastRatio,
  ROLE_TABLE,
  resolveRoleToken,
} from "../260910-if9-fix-light-dark-theme-color-family-consis/oklch-audit.mjs";

const __dirname = dirname(fileURLToPath(import.meta.url));
void __dirname; // kept for parity with the imported script's own layout; unused here

const HUE = 313.1;
const K_SWEEP = [0.85, 0.87, 0.9];
const K_PRIMARY = 0.85;
const DELTA_E_JOIN_THRESHOLD = 0.012;
const TEXT_FLOOR = 4.5;

// ---------------------------------------------------------------------
// New maths: OKLCh -> linear sRGB (inverse of oklch-audit.mjs's oklab/1),
// an in-gamut predicate, a maxC(L, H) bisection, OKLCh -> hex, OKLab ΔE.
// Matrices are Björn Ottosson's published OKLab ones (the exact inverse of
// the forward matrices `oklab()` already uses).
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

// In-gamut predicate: true when the OKLCh triple round-trips to a linear
// sRGB triple inside [0, 1] on every channel (a small epsilon absorbs
// floating-point noise at the exact gamut boundary the bisection walks
// toward).
function isInGamut(l, c, hDeg) {
  const EPS = 1e-6;
  const [r, g, b] = labToLinearRgb(oklchToLab(l, c, hDeg));
  return r >= -EPS && r <= 1 + EPS && g >= -EPS && g <= 1 + EPS && b >= -EPS && b <= 1 + EPS;
}

// maxC(L, H): the maximum in-gamut OKLCh chroma at a given lightness and
// hue, found by bisection on the in-gamut predicate above. 40 iterations
// over a [0, 0.5] bracket (sRGB never reaches C=0.5 at any L/H) converges
// to well beyond hex-quantisation precision.
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

// OKLab ΔE: plain Euclidean distance in OKLab space -- "close enough to be
// the same swatch" as a number, not an opinion (plan Task 2 action).
function deltaE(hexA, hexB) {
  const a = oklab(hexA);
  const b = oklab(hexB);
  return Math.sqrt((a.l - b.l) ** 2 + (a.a - b.a) ** 2 + (a.b - b.b) ** 2);
}

// findGamutPeakL: samples maxChroma across (loL, hiL) and returns the L
// that maximises it -- the "L62 gamut peak" non-anchor stop is this file's
// own measurement, not a hand-typed constant, mirroring the Q3 research
// gamut probe that found sRGB's chroma ceiling at this hue humps around
// L60.
function findGamutPeakL(loL, hiL, hDeg) {
  let bestL = loL;
  let bestC = -1;
  for (let l = loL; l <= hiL; l += 0.1) {
    const c = maxChroma(l, hDeg);
    if (c > bestC) {
      bestC = c;
      bestL = l;
    }
  }
  return bestL;
}

// ---------------------------------------------------------------------
// L ladder + anchors, derived from the LIVE palette (never hand-copied).
// Anchor definitions name which shipped role(s) occupy each anchor stop --
// this is the one place a ROLE NAME is written down (mirrors ROLE_TABLE's
// own "one place a token name is written" discipline in oklch-audit.mjs);
// every L/C VALUE still comes from parsing app.css.
// ---------------------------------------------------------------------

const ANCHOR_DEFS = [
  {
    stop: 100,
    name: "light base-200 / dark base-content (already literally shared)",
    sources: [
      { theme: "light", role: "base-200" },
      { theme: "dark", role: "base-content" },
    ],
  },
  { stop: 200, name: "light base-300", sources: [{ theme: "light", role: "base-300" }] },
  { stop: 400, name: "dark --pk-ink-brand", sources: [{ theme: "dark", role: "pk-ink-brand" }] },
  { stop: 600, name: "dark primary", sources: [{ theme: "dark", role: "primary" }] },
  { stop: 800, name: "dark base-300", sources: [{ theme: "dark", role: "base-300" }] },
  {
    stop: 900,
    name: "light primary / dark base-200 (D-HueMove's shared swatch)",
    sources: [
      { theme: "light", role: "primary" },
      { theme: "dark", role: "base-200" },
    ],
  },
  { stop: 950, name: "dark base-100", sources: [{ theme: "dark", role: "base-100" }] },
];

function average(values) {
  return values.reduce((sum, v) => sum + v, 0) / values.length;
}

function anchorFromRoles(palette, sources) {
  const ls = [];
  const cs = [];
  for (const { theme, role } of sources) {
    const hex = palette[theme][role];
    if (!hex) throw new Error(`Anchor source ${theme}.${role} not found in the live palette`);
    ls.push(oklchLightness(hex));
    cs.push(oklchChroma(hex));
  }
  return { l: average(ls), c: average(cs) };
}

// Builds the strictly-monotone 11-stop L ladder. Anchor stops take their L
// straight from the live palette (averaged across sources for the one
// merged stop, D-HueMove). Non-anchor "gap"/"headroom" stops are derived
// by interpolation between their bracketing anchors, except the L62 gamut
// peak, which is FOUND by findGamutPeakL rather than interpolated -- it is
// a property of the gamut at this hue, not a midpoint between two shipped
// values.
function buildLadder(palette, hue) {
  const anchors = {};
  for (const def of ANCHOR_DEFS) {
    anchors[def.stop] = { ...anchorFromRoles(palette, def.sources), name: def.name };
  }

  const lTop = anchors[100].l + (100 - anchors[100].l) * 0.5;
  const lGap80 = (anchors[200].l + anchors[400].l) / 2;
  const lGap40 = (anchors[600].l + anchors[800].l) / 2;
  const lPeak = findGamutPeakL(anchors[600].l + 0.5, anchors[400].l - 0.5, hue);

  const ladder = [
    { stop: 50, l: lTop, anchor: null },
    { stop: 100, l: anchors[100].l, anchor: anchors[100] },
    { stop: 200, l: anchors[200].l, anchor: anchors[200] },
    { stop: 300, l: lGap80, anchor: null },
    { stop: 400, l: anchors[400].l, anchor: anchors[400] },
    { stop: 500, l: lPeak, anchor: null },
    { stop: 600, l: anchors[600].l, anchor: anchors[600] },
    { stop: 700, l: lGap40, anchor: null },
    { stop: 800, l: anchors[800].l, anchor: anchors[800] },
    { stop: 900, l: anchors[900].l, anchor: anchors[900] },
    { stop: 950, l: anchors[950].l, anchor: anchors[950] },
  ];

  for (let i = 1; i < ladder.length; i++) {
    if (ladder[i].l >= ladder[i - 1].l) {
      throw new Error(
        `Ladder is not strictly monotone: stop ${ladder[i - 1].stop} (L${ladder[i - 1].l.toFixed(1)}) ` +
          `is not greater than stop ${ladder[i].stop} (L${ladder[i].l.toFixed(1)}) -- this is a bug in ` +
          "the ladder derivation, not a normal audit finding.",
      );
    }
  }

  return ladder;
}

function buildFlatRamp(ladder, k, hue) {
  return ladder.map(({ stop, l }) => {
    const c = k * maxChroma(l, hue);
    return { stop, l, c, h: hue, hex: oklchToHex(l, c, hue) };
  });
}

function buildAnchoredRamp(ladder, k, hue) {
  return ladder.map(({ stop, l, anchor }) => {
    const c = anchor ? Math.min(anchor.c, maxChroma(l, hue)) : k * maxChroma(l, hue);
    return { stop, l, c, h: hue, hex: oklchToHex(l, c, hue) };
  });
}

// ---------------------------------------------------------------------
// Contrast graph: the pairs a role's colour is actually painted against.
// This is the audit's own equivalent of ROLE_TABLE -- names are written
// down here, values always come from the live (or candidate) palette.
// ---------------------------------------------------------------------

const CONTENT_ROLES = ["primary", "secondary", "accent", "neutral", "info", "success", "warning", "error"];

// Every pair here is grounded in either a PINNED catalog_show_test.exs
// assertion or daisyUI's own text-on-fill convention (every `X`/
// `X-content` role pair, both themes). The theme-specific pairs are
// deliberately NOT symmetric across themes -- they match
// `<measured_baseline>`'s own "Pinned WCAG floors" table exactly, which
// pins DIFFERENT ground pairs per theme (dark neutral-on-base-100, light
// neutral-on-base-200; light primary-on-base-100, but no equivalent dark
// primary-on-base-100 pair). Applying "primary vs base-100" to DARK too
// would wrongly flag dark's own `--color-primary` (2.35:1 on its own
// base-100) as a contrast failure -- that pair was true before quick task
// 260910-gck deliberately moved dark's outline-CTA text OFF primary onto
// `--pk-ink-brand` for exactly this reason (dark primary is a FILL only
// now, never rendered as bare text against the page). Its real, current
// constraint is the generic `primary-content` vs `primary` pair below,
// which does apply to both themes and does hold.
//
// Deliberately NOT included at all: a `base-300`-vs-`base-100`/`base-200`
// "border visibility" pair -- no test in this suite pins one, and the LIVE
// shipped palette itself already sits below 3:1 there (light base-300/
// base-200 measures 1.22:1 today), so treating it as a floor would falsely
// "OFF-RAMP" or "DISQUALIFY" candidates on a constraint the app never
// actually enforces.
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
// Role-by-role JOIN / OFF-RAMP audit
// ---------------------------------------------------------------------

function evaluateCandidate(label, ramp, palette) {
  const roleResults = [];

  for (const theme of ["light", "dark"]) {
    const pairs = buildContrastPairs(theme);
    for (const role of Object.keys(palette[theme])) {
      const shippedHex = palette[theme][role];

      let best = null;
      for (const s of ramp) {
        const de = deltaE(shippedHex, s.hex);
        if (!best || de < best.deltaE) best = { stop: s.stop, hex: s.hex, deltaE: de };
      }

      const forcedJoin = theme === "light" && (role === "primary" || role === "accent-content");
      const forcedOffSemantic = SEMANTIC_HUE_ROLES.has(role);
      const forcedOffWhite = shippedHex === "#FFFFFF";

      const contrastDetails = [];
      let contrastOk = true;
      for (const pair of pairs) {
        if (pair.a !== role && pair.b !== role) continue;
        const otherRole = pair.a === role ? pair.b : pair.a;
        const otherHex = palette[theme][otherRole];
        if (!otherHex) continue;
        const ratio = contrastRatio(best.hex, otherHex);
        contrastDetails.push({ pair: `${pair.a}/${pair.b}`, ratio, floor: pair.floor });
        if (ratio < pair.floor) contrastOk = false;
      }

      const passesDelta = forcedJoin || best.deltaE <= DELTA_E_JOIN_THRESHOLD;

      let verdict;
      let reason = null;
      if (forcedOffSemantic) {
        verdict = "OFF-RAMP";
        reason = "semantic hue (D-Semantics) -- never joins the brand ramp";
      } else if (forcedOffWhite) {
        verdict = "OFF-RAMP";
        reason = "achromatic white -- no ramp stop invented for white";
      } else if (passesDelta && contrastOk) {
        verdict = "JOIN";
      } else {
        verdict = "OFF-RAMP";
        if (!passesDelta && !contrastOk) {
          reason = `chroma tier (dE ${best.deltaE.toFixed(4)} > ${DELTA_E_JOIN_THRESHOLD}) + contrast`;
        } else if (!passesDelta) {
          reason = `chroma tier (dE ${best.deltaE.toFixed(4)} > ${DELTA_E_JOIN_THRESHOLD})`;
        } else {
          const failing = contrastDetails.filter((c) => c.ratio < c.floor);
          reason = `contrast (${failing.map((f) => `${f.pair} ${f.ratio.toFixed(2)}:1 < ${f.floor}:1`).join("; ")})`;
        }
      }

      roleResults.push({
        theme,
        role,
        shippedHex,
        nearestStop: best.stop,
        nearestHex: best.hex,
        deltaE: best.deltaE,
        forcedJoin,
        verdict,
        reason,
        contrastDetails,
      });
    }
  }

  return { label, ramp, roleResults };
}

function resolvedPaletteForCandidate(evaluation, palette) {
  const resolved = { light: { ...palette.light }, dark: { ...palette.dark } };
  for (const r of evaluation.roleResults) {
    resolved[r.theme][r.role] = r.verdict === "JOIN" ? r.nearestHex : r.shippedHex;
  }
  return resolved;
}

// ---------------------------------------------------------------------
// Pinned WCAG floor recheck: the explicit trio/pair list this plan names,
// plus every `.pk-pill-*`/`.pk-chip*` fill/border pair from ROLE_TABLE
// (imported, not re-declared -- D-NoFourthCopy's spirit extends to role
// names too: one inventory, not two that can drift apart).
// ---------------------------------------------------------------------

function recheckPinnedFloors(resolved) {
  const checks = [
    { label: "dark --pk-ink-brand on base-100", theme: "dark", a: "pk-ink-brand", b: "base-100", floor: TEXT_FLOOR },
    { label: "dark --pk-ink-brand on base-200", theme: "dark", a: "pk-ink-brand", b: "base-200", floor: TEXT_FLOOR },
    { label: "dark --pk-ink-brand on base-300", theme: "dark", a: "pk-ink-brand", b: "base-300", floor: TEXT_FLOOR },
    { label: "dark neutral on base-100", theme: "dark", a: "neutral", b: "base-100", floor: TEXT_FLOOR },
    { label: "dark neutral on base-200", theme: "dark", a: "neutral", b: "base-200", floor: TEXT_FLOOR },
    { label: "light primary on base-100 (white)", theme: "light", a: "primary", b: "base-100", floor: TEXT_FLOOR },
    { label: "dark primary-content on primary", theme: "dark", a: "primary-content", b: "primary", floor: TEXT_FLOOR },
  ];

  const results = checks.map((c) => {
    const hexA = resolved[c.theme][c.a];
    const hexB = resolved[c.theme][c.b];
    const ratio = contrastRatio(hexA, hexB);
    return { ...c, hexA, hexB, ratio, pass: ratio >= c.floor };
  });

  // `.pk-pill-*`/`.pk-chip*` INK legibility, reusing ROLE_TABLE (imported,
  // not re-declared). This generalises the ONE fill/border/ink pair
  // actually pinned in catalog_show_test.exs today (`.pk-pill-tag`'s
  // ink-vs-fill text floor, 4.5:1) to every tone in the same table.
  // Deliberately NOT a fill-vs-border or border-vs-page check: no test in
  // this suite pins either, and the LIVE shipped palette already sits
  // below 3:1 on several such pairs today (e.g. light base-300 vs
  // base-200 measures 1.22:1 in production right now) -- treating either
  // as a floor would falsely "DISQUALIFY" a candidate on a constraint the
  // app never actually enforces, rather than one the ramp itself costs.
  for (const spec of ROLE_TABLE) {
    for (const themeName of ["light", "dark"]) {
      const fillToken = resolveRoleToken(spec.fill, themeName);
      const inkToken = resolveRoleToken(spec.ink, themeName);
      const groundToken = fillToken && fillToken !== "transparent" ? fillToken : "base-100";
      const groundHex = resolved[themeName][groundToken];

      if (inkToken && inkToken !== "transparent" && groundHex) {
        const inkHex = resolved[themeName][inkToken];
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

// ---------------------------------------------------------------------
// Printing
// ---------------------------------------------------------------------

function fmt(n, decimals = 1) {
  return n.toFixed(decimals);
}

function printRampTable(ramp) {
  console.log("stop  L      C       H      hex");
  for (const s of ramp) {
    console.log(`${String(s.stop).padEnd(5)} ${fmt(s.l).padEnd(6)} ${fmt(s.c, 3).padEnd(7)} ${fmt(s.h).padEnd(6)} ${s.hex}`);
  }
}

function printRoleAudit(evaluation) {
  console.log(`\n${evaluation.label} -- role-by-role JOIN/OFF-RAMP audit`);
  console.log("theme  role                   shipped   nearest  dE       verdict    reason");
  for (const r of evaluation.roleResults) {
    console.log(
      `${r.theme.padEnd(6)} ${r.role.padEnd(22)} ${r.shippedHex.padEnd(9)} ${String(r.nearestStop).padEnd(8)} ` +
        `${fmt(r.deltaE, 4).padEnd(8)} ${r.verdict.padEnd(10)} ${r.reason ?? ""}`,
    );
  }

  const joined = evaluation.roleResults.filter((r) => r.verdict === "JOIN");
  const offRamp = evaluation.roleResults.filter((r) => r.verdict === "OFF-RAMP");

  console.log(`\n${evaluation.label} sharable set (JOIN -- ${joined.length} roles):`);
  if (joined.length === 0) {
    console.log("  none");
  } else {
    for (const r of joined) {
      console.log(`  ${r.theme}.${r.role} -> stop ${r.nearestStop} (${r.nearestHex}), dE=${fmt(r.deltaE, 4)}`);
    }
  }

  console.log(`\n${evaluation.label} blocked set (OFF-RAMP -- ${offRamp.length} roles):`);
  if (offRamp.length === 0) {
    console.log("  none");
  } else {
    for (const r of offRamp) {
      console.log(`  ${r.theme}.${r.role} -> nearest stop ${r.nearestStop} (${r.nearestHex}), reason: ${r.reason}`);
    }
  }

  const stopCounts = {};
  for (const r of joined) {
    stopCounts[r.nearestStop] = (stopCounts[r.nearestStop] || 0) + 1;
  }
  const sharedStops = Object.entries(stopCounts).filter(([, count]) => count >= 2);
  console.log(`\n${evaluation.label} distinct stops worn by 2+ roles across both themes: ${sharedStops.length}`);
  for (const [stop, count] of sharedStops) {
    const roles = joined.filter((r) => String(r.nearestStop) === stop).map((r) => `${r.theme}.${r.role}`);
    console.log(`  stop ${stop}: ${count} roles -- ${roles.join(", ")}`);
  }

  return { joined, offRamp, sharedStopCount: sharedStops.length };
}

function printFloorRecheck(evaluation, palette) {
  console.log(`\n${evaluation.label} -- WCAG floor recheck`);
  const resolved = resolvedPaletteForCandidate(evaluation, palette);
  const floorResults = recheckPinnedFloors(resolved);
  for (const f of floorResults) {
    console.log(
      `  ${f.pass ? "HOLDS " : "BREAKS"} ${f.label}: ${f.hexA} vs ${f.hexB} = ${fmt(f.ratio, 2)}:1 (floor ${f.floor}:1)`,
    );
  }
  const broken = floorResults.filter((f) => !f.pass);
  if (broken.length > 0) {
    console.log(`  DISQUALIFIED: ${broken.length} floor(s) broken -- this candidate does not qualify as-is.`);
  } else {
    console.log("  All pinned floors hold.");
  }
  return { floorResults, broken };
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

  let palette;
  try {
    palette = buildPalette(css);
  } catch (err) {
    console.error(`FAIL: could not parse the live palette: ${err.message}`);
    process.exit(1);
  }

  const ladder = buildLadder(palette, HUE);

  console.log("Ramp audit -- quick task 260910-l7q");
  console.log(`Live palette read from ${APP_CSS_PATH}`);
  console.log(`Hue: ${HUE} deg -- 11 stops: ${ladder.map((s) => s.stop).join(", ")}`);
  console.log(`Ladder (L, descending): ${ladder.map((s) => fmt(s.l)).join(", ")}`);

  console.log("\n=== FLAT k-sweep ===");
  const flatRamps = {};
  for (const k of K_SWEEP) {
    const ramp = buildFlatRamp(ladder, k, HUE);
    flatRamps[k] = ramp;
    console.log(`\nFLAT candidate, k=${k}`);
    printRampTable(ramp);
  }

  const flatMain = flatRamps[K_PRIMARY];
  const anchoredRamp = buildAnchoredRamp(ladder, K_PRIMARY, HUE);

  console.log(`\n=== ANCHORED candidate (k=${K_PRIMARY} baseline for non-anchor stops) ===`);
  printRampTable(anchoredRamp);

  const flatEval = evaluateCandidate("FLAT", flatMain, palette);
  const flatAudit = printRoleAudit(flatEval);
  const flatFloors = printFloorRecheck(flatEval, palette);

  const anchoredEval = evaluateCandidate("ANCHORED", anchoredRamp, palette);
  const anchoredAudit = printRoleAudit(anchoredEval);
  const anchoredFloors = printFloorRecheck(anchoredEval, palette);

  console.log("\n=== SUMMARY ===");
  console.log(
    `FLAT (k=${K_PRIMARY}):     ${flatAudit.joined.length} on-ramp, ${flatAudit.offRamp.length} off-ramp, ` +
      `${flatAudit.sharedStopCount} shared stop(s), ${flatFloors.broken.length} broken floor(s)`,
  );
  console.log(
    `ANCHORED:          ${anchoredAudit.joined.length} on-ramp, ${anchoredAudit.offRamp.length} off-ramp, ` +
      `${anchoredAudit.sharedStopCount} shared stop(s), ${anchoredFloors.broken.length} broken floor(s)`,
  );

  console.log("\nassets/css/app.css was NOT modified by this script.");
  process.exit(0);
}

main();
