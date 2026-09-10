#!/usr/bin/env node
// Zero-dependency Node oracle for sketch 054 (dark-mode color composition).
//
// Parses the per-frame `.pk-sk-frame[data-variant="X"] { ... }` token blocks
// straight out of this sketch's own index.html (single source — the page's
// on-screen readout and this CLI therefore can never disagree about what a
// variant's values are), then asserts:
//   1. Exactly 4 variant blocks exist (round 2: "a" reference + 3 warm
//      primary/secondary/accent candidates layered on Variant A's ladder,
//      which the developer already picked in round 1 — see README).
//   2. Each block declares all 13 mapped color tokens.
//   3. For every block, the 4 measured WCAG ratios are each >= 4.5:1.
//   4. Each of the 3 warm proposals (w1/w2/w3) differs from "a" in at least
//      one declared token value, so no proposal is a silent no-op.
//
// Exit 0 + a per-variant table on success. Exit 1 + the specific failures
// otherwise.

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const INDEX_HTML_PATH = join(__dirname, "index.html");

const REQUIRED_TOKENS = [
  "bg",
  "surface",
  "surface-2",
  "border",
  "text",
  "text-muted",
  "primary",
  "primary-content",
  "secondary",
  "accent-bg",
  "accent-text",
  "danger",
  "success",
];

const CONTRAST_FLOOR = 4.5;
const EXPECTED_VARIANT_COUNT = 4;
const CONTROL_ID = "a";

function hexToRgb(hex) {
  const h = hex.trim().replace("#", "");
  return [0, 2, 4].map((i) => parseInt(h.substr(i, 2), 16));
}

function relLuminance([r, g, b]) {
  const f = (v) => {
    v /= 255;
    return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
  };
  return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b);
}

function contrastRatio(hexA, hexB) {
  const lA = relLuminance(hexToRgb(hexA));
  const lB = relLuminance(hexToRgb(hexB));
  const lighter = Math.max(lA, lB);
  const darker = Math.min(lA, lB);
  return (lighter + 0.05) / (darker + 0.05);
}

function parseVariantBlocks(html) {
  const blockRe = /\.pk-sk-frame\[data-variant="([a-z0-9-]+)"\]\s*\{([\s\S]*?)\}/g;
  const tokenRe = /--color-([a-z0-9-]+):\s*(#[0-9A-Fa-f]{6})\s*;/g;

  const variants = [];
  let match;
  while ((match = blockRe.exec(html)) !== null) {
    const [, id, body] = match;
    const tokens = {};
    let tokenMatch;
    tokenRe.lastIndex = 0;
    while ((tokenMatch = tokenRe.exec(body)) !== null) {
      const [, tokenName, tokenValue] = tokenMatch;
      tokens[tokenName] = tokenValue.toUpperCase();
    }
    variants.push({ id, tokens });
  }
  return variants;
}

function main() {
  let html;
  try {
    html = readFileSync(INDEX_HTML_PATH, "utf8");
  } catch (err) {
    console.error(`FAIL: could not read ${INDEX_HTML_PATH}: ${err.message}`);
    process.exit(1);
  }

  const variants = parseVariantBlocks(html);
  const failures = [];

  if (variants.length !== EXPECTED_VARIANT_COUNT) {
    failures.push(
      `Expected exactly ${EXPECTED_VARIANT_COUNT} variant blocks, found ${variants.length} (${variants.map((v) => v.id).join(", ") || "none"})`,
    );
  }

  const control = variants.find((v) => v.id === CONTROL_ID);
  if (!control) {
    failures.push(`No "${CONTROL_ID}" variant block found — cannot compare proposals against it`);
  }

  const rows = [];

  for (const variant of variants) {
    const missing = REQUIRED_TOKENS.filter((t) => !variant.tokens[t]);
    if (missing.length > 0) {
      failures.push(`Variant "${variant.id}" is missing token(s): ${missing.map((t) => `--color-${t}`).join(", ")}`);
      continue;
    }

    const { tokens } = variant;
    const bgLum = relLuminance(hexToRgb(tokens["bg"]));
    const textOnBg = contrastRatio(tokens["text"], tokens["bg"]);
    const mutedOnBg = contrastRatio(tokens["text-muted"], tokens["bg"]);
    const textOnSurface = contrastRatio(tokens["text"], tokens["surface"]);
    const primaryContentOnPrimary = contrastRatio(tokens["primary-content"], tokens["primary"]);

    const ratios = {
      "text-on-bg": textOnBg,
      "muted-on-bg": mutedOnBg,
      "text-on-surface": textOnSurface,
      "primary-content-on-primary": primaryContentOnPrimary,
    };

    for (const [label, ratio] of Object.entries(ratios)) {
      if (ratio < CONTRAST_FLOOR) {
        failures.push(
          `Variant "${variant.id}": ${label} ratio ${ratio.toFixed(2)}:1 is below the ${CONTRAST_FLOOR}:1 floor`,
        );
      }
    }

    if (variant.id !== CONTROL_ID && control) {
      const isDistinct = REQUIRED_TOKENS.some((t) => variant.tokens[t] !== control.tokens[t]);
      if (!isDistinct) {
        failures.push(`Variant "${variant.id}" is a silent no-op — identical to "${CONTROL_ID}" on every token`);
      }
    }

    rows.push({
      id: variant.id,
      bgLum: bgLum.toFixed(4),
      primary: tokens["primary"],
      primaryContent: tokens["primary-content"],
      textOnBg: textOnBg.toFixed(2),
      mutedOnBg: mutedOnBg.toFixed(2),
      textOnSurface: textOnSurface.toFixed(2),
      primaryContentOnPrimary: primaryContentOnPrimary.toFixed(2),
    });
  }

  if (rows.length > 0) {
    console.log(
      "variant".padEnd(9) +
        "primary".padEnd(10) +
        "primary-content".padEnd(18) +
        "text/bg".padEnd(10) +
        "muted/bg".padEnd(11) +
        "text/surf".padEnd(11) +
        "pContent/p",
    );
    for (const r of rows) {
      console.log(
        r.id.padEnd(9) +
          r.primary.padEnd(10) +
          r.primaryContent.padEnd(18) +
          `${r.textOnBg}:1`.padEnd(10) +
          `${r.mutedOnBg}:1`.padEnd(11) +
          `${r.textOnSurface}:1`.padEnd(11) +
          `${r.primaryContentOnPrimary}:1`,
      );
    }
  }

  if (failures.length > 0) {
    console.error("\nFAIL:");
    for (const f of failures) console.error(`  - ${f}`);
    process.exit(1);
  }

  console.log(
    `\nOK: ${rows.length} variants x ${REQUIRED_TOKENS.length} tokens, every ratio >= ${CONTRAST_FLOOR}:1, every warm proposal distinct from "${CONTROL_ID}".`,
  );
  process.exit(0);
}

main();
