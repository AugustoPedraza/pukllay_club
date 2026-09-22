#!/usr/bin/env python3
"""Re-bake `priv/static/images/og-fallback.webp` from `assets/css/app.css`'s
live brand-ramp values.

Composition is locked (phase 01.8 D-04/D-05, `share-card.md`): a centered
vertical stack of `isologo-dark.png` (190px wide), the "PUKLLAY CLUB" wordmark
(Bebas Neue 68px, 0.08em tracking, white), and the tagline (Inter 27px,
0.01em tracking, `TAGLINE_HEX`), each separated by a 20px gap, on a solid
`BACKGROUND_HEX` canvas. Pixel source: `export.html` in
`.claude/skills/sketch-findings-pukllay_club/sources/057-og-fallback-share-card/`.

Only the two colours are parameterised. Composition, fonts, and geometry are
NOT redesigned (D-3).

Usage:
    python3 tools/og-fallback/generate_og_fallback.py \
        [--out priv/static/images/og-fallback.webp] [--preview DIR]

Re-run this after any brand-ramp rotation (see `share-card.md` "What to
Avoid"). The script self-verifies its own output and exits non-zero on any
failure, printing every measured value.
"""

import argparse
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

REPO_ROOT = Path(__file__).resolve().parents[2]
APP_CSS_PATH = REPO_ROOT / "assets" / "css" / "app.css"
ISOLOGO_PATH = REPO_ROOT / "priv" / "static" / "images" / "isologo-dark.png"
BEBAS_FONT_PATH = REPO_ROOT / "priv" / "static" / "fonts" / "bebas-neue-400-latin.woff2"
INTER_FONT_PATH = REPO_ROOT / "priv" / "static" / "fonts" / "inter-400-latin.woff2"
DEFAULT_OUT = REPO_ROOT / "priv" / "static" / "images" / "og-fallback.webp"

CANVAS_W, CANVAS_H = 1200, 630
MARK_W = 190
WORDMARK_SIZE = 68
WORDMARK_TRACKING_EM = 0.08
TAGLINE_SIZE = 27
TAGLINE_LINE_HEIGHT = 1.3
TAGLINE_TRACKING_EM = 0.01
GAP = 20
WORDMARK_TEXT = "Pukllay Club"
TAGLINE_TEXT = "Tu club de juegos de mesa modernos — Jujuy"

# Hardcoded expectations. The parse below MUST agree with these, or the
# generator refuses to run — this pair is what the ExUnit gates (Task 2)
# read as ground truth for "did the generator's constant track app.css".
EXPECTED_BACKGROUND_HEX = "#4A187F"
EXPECTED_TAGLINE_HEX = "#DED4F3"

# Retired colours this re-bake must eliminate.
RETIRED_BACKGROUND_HEX = "#551670"
RETIRED_TAGLINE_HEX = "#E3D3F0"

# Previously-shipped file, used only for the geometry-mask comparison. Not a
# behavioural input to the bake itself.
PREVIOUS_ASSET_PATH = REPO_ROOT / "priv" / "static" / "images" / "og-fallback.webp"

GEOMETRY_AGREEMENT_FLOOR = 0.985
MASK_DELTA_THRESHOLD = 6


def parse_css_var(css_text: str, var_name: str, within_light_theme: bool = False) -> str:
    """Extract a hex literal for `--var-name: #RRGGBB;` from `app.css`.

    When `within_light_theme` is True, scope the search to the daisyUI
    `@plugin "..."` block whose `name:` is `"light"` (light and dark themes
    both declare --color-base-300, with different values).
    """
    if within_light_theme:
        light_block_match = re.search(
            r'@plugin\s+"[^"]*daisyui-theme"\s*\{[^{}]*?name:\s*"light";.*?\n\}',
            css_text,
            re.DOTALL,
        )
        if not light_block_match:
            raise ValueError('Could not locate the daisyUI theme block with name: "light" in app.css')
        search_text = light_block_match.group(0)
    else:
        search_text = css_text

    match = re.search(rf"--{re.escape(var_name)}:\s*(#[0-9A-Fa-f]{{6}})\s*;", search_text)
    if not match:
        raise ValueError(f"Could not parse --{var_name} out of app.css")
    return match.group(1).upper()


def load_colours():
    css_text = APP_CSS_PATH.read_text(encoding="utf-8")

    background_hex = parse_css_var(css_text, "pk-ramp-800", within_light_theme=False)
    tagline_hex = parse_css_var(css_text, "color-base-300", within_light_theme=True)

    if background_hex != EXPECTED_BACKGROUND_HEX:
        raise ValueError(
            f"--pk-ramp-800 parsed as {background_hex}, expected {EXPECTED_BACKGROUND_HEX}. "
            "app.css has drifted since this generator's constants were last reviewed -- "
            "update EXPECTED_BACKGROUND_HEX (and the ExUnit gate reading it) deliberately, "
            "do not silently accept a new value."
        )
    if tagline_hex != EXPECTED_TAGLINE_HEX:
        raise ValueError(
            f"light --color-base-300 parsed as {tagline_hex}, expected {EXPECTED_TAGLINE_HEX}. "
            "app.css has drifted since this generator's constants were last reviewed -- "
            "update EXPECTED_TAGLINE_HEX (and the ExUnit gate reading it) deliberately, "
            "do not silently accept a new value."
        )

    return background_hex, tagline_hex


BACKGROUND_HEX, TAGLINE_HEX = load_colours()


def hex_to_rgb(hex_str: str) -> tuple[int, int, int]:
    hex_str = hex_str.lstrip("#")
    return tuple(int(hex_str[i : i + 2], 16) for i in (0, 2, 4))


def draw_tracked_text(draw: ImageDraw.ImageDraw, xy, text, font, fill, tracking_px):
    """Pillow has no letter-spacing. Draw glyph by glyph, advancing by each
    glyph's own advance plus `tracking_px`. Returns the run's rendered width
    EXCLUDING trailing tracking after the final glyph (the correct value to
    centre against)."""
    x, y = xy
    start_x = x
    for ch in text:
        draw.text((x, y), ch, font=font, fill=fill)
        advance = draw.textlength(ch, font=font)
        x += advance + tracking_px
    # Subtract the tracking added after the last glyph -- it was never
    # visually part of the run.
    total_width = x - start_x - tracking_px
    return total_width


def measure_tracked_width(font, text, tracking_px):
    dummy = Image.new("RGB", (1, 1))
    d = ImageDraw.Draw(dummy)
    width = 0.0
    for ch in text:
        width += d.textlength(ch, font=font)
    width += tracking_px * (len(text) - 1)
    return width


def build_image():
    background_rgb = hex_to_rgb(BACKGROUND_HEX)
    tagline_rgb = hex_to_rgb(TAGLINE_HEX)

    canvas = Image.new("RGB", (CANVAS_W, CANVAS_H), background_rgb)

    # Mark: alpha-composite (not paste) isologo-dark.png onto the purple.
    isologo = Image.open(ISOLOGO_PATH)
    if isologo.mode != "RGBA":
        raise ValueError(f"Expected isologo-dark.png to be RGBA, got {isologo.mode}")
    mark_w = MARK_W
    mark_h = round(isologo.height * (mark_w / isologo.width))
    isologo_resized = isologo.resize((mark_w, mark_h), Image.LANCZOS)

    bebas_font = ImageFont.truetype(str(BEBAS_FONT_PATH), WORDMARK_SIZE)
    inter_font = ImageFont.truetype(str(INTER_FONT_PATH), TAGLINE_SIZE)

    wordmark_tracking_px = WORDMARK_TRACKING_EM * WORDMARK_SIZE
    tagline_tracking_px = TAGLINE_TRACKING_EM * TAGLINE_SIZE

    wordmark_str = WORDMARK_TEXT.upper()
    tagline_str = TAGLINE_TEXT

    wordmark_line_h = WORDMARK_SIZE
    tagline_line_h = round(TAGLINE_SIZE * TAGLINE_LINE_HEIGHT)

    total_h = mark_h + GAP + wordmark_line_h + GAP + tagline_line_h
    top = (CANVAS_H - total_h) // 2

    draw = ImageDraw.Draw(canvas)

    # Mark, centred horizontally.
    mark_x = (CANVAS_W - mark_w) // 2
    mark_y = top
    canvas.paste(isologo_resized, (mark_x, mark_y), isologo_resized)

    # Wordmark, centred horizontally, vertically centred within its line box.
    wordmark_width = measure_tracked_width(bebas_font, wordmark_str, wordmark_tracking_px)
    wordmark_x = (CANVAS_W - wordmark_width) / 2
    wordmark_y_box_top = mark_y + mark_h + GAP
    # Pillow's textbbox for the ascent/descent varies per glyph; anchor by
    # drawing at the box top since line-height 1 == font size here.
    draw_tracked_text(
        draw,
        (wordmark_x, wordmark_y_box_top),
        wordmark_str,
        bebas_font,
        (255, 255, 255),
        wordmark_tracking_px,
    )

    # Tagline, centred horizontally, vertically centred within its
    # line-height-1.3 line box.
    tagline_width = measure_tracked_width(inter_font, tagline_str, tagline_tracking_px)
    tagline_x = (CANVAS_W - tagline_width) / 2
    tagline_box_top = wordmark_y_box_top + wordmark_line_h + GAP
    # Centre the glyph's own rendered height within the 1.3x line box.
    tagline_bbox = draw.textbbox((0, 0), "Áy", font=inter_font)
    glyph_h = tagline_bbox[3] - tagline_bbox[1]
    tagline_y = tagline_box_top + (tagline_line_h - glyph_h) / 2 - tagline_bbox[1]
    draw_tracked_text(
        draw,
        (tagline_x, tagline_y),
        tagline_str,
        inter_font,
        tagline_rgb,
        tagline_tracking_px,
    )

    return canvas


def ink_mask(image: Image.Image, background_rgb: tuple[int, int, int]):
    rgb = image.convert("RGB")
    pixels = rgb.load()
    w, h = rgb.size
    mask = bytearray(w * h)
    br, bg, bb = background_rgb
    idx = 0
    for y in range(h):
        for x in range(w):
            r, g, b = pixels[x, y]
            dr, dg, db = r - br, g - bg, b - bb
            within_bg = abs(dr) <= MASK_DELTA_THRESHOLD and abs(dg) <= MASK_DELTA_THRESHOLD and abs(db) <= MASK_DELTA_THRESHOLD
            mask[idx] = 0 if within_bg else 1
            idx += 1
    return mask


def load_previous_asset(previous_path: Path):
    """Load the previously-shipped asset fully into memory (pixels
    force-loaded) BEFORE the output file at the same path gets overwritten.
    Must be called prior to `image.save(args.out, ...)` when `--out` targets
    the same path as `previous_path` (the default), or this would silently
    compare the new file against itself."""
    if not previous_path.exists():
        print(f"WARNING: no previous asset at {previous_path}; skipping geometry-mask check.")
        return None

    previous_image = Image.open(previous_path).convert("RGB")
    previous_image.load()  # force full decode into memory now, not lazily later
    if previous_image.size != (CANVAS_W, CANVAS_H):
        print(
            f"WARNING: previous asset is {previous_image.size}, expected {(CANVAS_W, CANVAS_H)}; "
            "skipping geometry-mask check."
        )
        return None
    return previous_image


def geometry_agreement(new_image: Image.Image, previous_image):
    if previous_image is None:
        return None

    prev_rgb = previous_image.load()
    prev_bg = prev_rgb[0, 0]

    new_mask = ink_mask(new_image, hex_to_rgb(BACKGROUND_HEX))
    prev_mask = ink_mask(previous_image, prev_bg)

    total = len(new_mask)
    agree = sum(1 for a, b in zip(new_mask, prev_mask) if a == b)
    return agree / total


def self_verify(image: Image.Image, out_path: Path, previous_image):
    rgb = image.convert("RGB")

    assert image.size == (CANVAS_W, CANVAS_H), f"Decoded size is {image.size}, expected {(CANVAS_W, CANVAS_H)}"
    print(f"OK: decoded size {image.size}")

    background_rgb = hex_to_rgb(BACKGROUND_HEX)
    sample_points = [(0, 0), (CANVAS_W - 1, 0), (0, CANVAS_H - 1), (CANVAS_W - 1, CANVAS_H - 1), (10, 315)]
    for xy in sample_points:
        actual = rgb.getpixel(xy)
        assert actual == background_rgb, f"Pixel {xy} is {actual}, expected background {background_rgb} ({BACKGROUND_HEX})"
    print(f"OK: all {len(sample_points)} background sample points equal {BACKGROUND_HEX}")

    census = {c for _count, c in rgb.getcolors(maxcolors=2_000_000)}
    tagline_rgb = hex_to_rgb(TAGLINE_HEX)
    assert tagline_rgb in census, f"Tagline colour {TAGLINE_HEX} does not occur anywhere in the decoded image"
    print(f"OK: tagline colour {TAGLINE_HEX} present ({len(census)} distinct colours total)")

    retired_bg_rgb = hex_to_rgb(RETIRED_BACKGROUND_HEX)
    retired_tagline_rgb = hex_to_rgb(RETIRED_TAGLINE_HEX)
    assert retired_bg_rgb not in census, f"Retired background colour {RETIRED_BACKGROUND_HEX} still present"
    assert retired_tagline_rgb not in census, f"Retired tagline colour {RETIRED_TAGLINE_HEX} still present"
    print(f"OK: neither retired colour ({RETIRED_BACKGROUND_HEX}, {RETIRED_TAGLINE_HEX}) present")

    agreement = geometry_agreement(image, previous_image)
    if agreement is not None:
        pct = agreement * 100
        print(f"Geometry-mask agreement vs previously-shipped asset: {pct:.4f}%")
        assert agreement >= GEOMETRY_AGREEMENT_FLOOR, (
            f"Geometry-mask agreement {pct:.4f}% is below the {GEOMETRY_AGREEMENT_FLOOR * 100}% floor -- "
            "composition has shifted, not just colour."
        )
        print(f"OK: geometry-mask agreement {pct:.4f}% >= {GEOMETRY_AGREEMENT_FLOOR * 100}% floor")


def write_previews(image: Image.Image, preview_dir: Path):
    preview_dir.mkdir(parents=True, exist_ok=True)
    for width, name in [(300, "preview-whatsapp-300w.png"), (340, "preview-x-twitter-340w.png")]:
        height = round(CANVAS_H * (width / CANVAS_W))
        resized = image.resize((width, height), Image.LANCZOS)
        out = preview_dir / name
        resized.save(out, "PNG")
        print(f"Wrote preview: {out}")
    full_out = preview_dir / "preview-full-1200x630.png"
    image.save(full_out, "PNG")
    print(f"Wrote preview: {full_out}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--out", type=Path, default=DEFAULT_OUT, help="Output .webp path")
    parser.add_argument("--preview", type=Path, default=None, help="Directory to write preview PNGs (never committed)")
    args = parser.parse_args()

    print(f"Background: {BACKGROUND_HEX} (from --pk-ramp-800)")
    print(f"Tagline:    {TAGLINE_HEX} (from light --color-base-300)")

    # Snapshot the previously-shipped asset into memory BEFORE it gets
    # overwritten below (--out defaults to this exact path).
    previous_image = load_previous_asset(PREVIOUS_ASSET_PATH)

    image = build_image()

    args.out.parent.mkdir(parents=True, exist_ok=True)
    image.save(args.out, "WEBP", lossless=True, method=6)
    print(f"Wrote: {args.out} ({args.out.stat().st_size} bytes)")

    # Re-open the saved file for verification, so the check runs against the
    # actual encoded bytes, not the in-memory canvas.
    saved = Image.open(args.out)
    self_verify(saved, args.out, previous_image)

    if args.preview:
        write_previews(saved.convert("RGB"), args.preview)

    print("ALL CHECKS PASSED")


if __name__ == "__main__":
    try:
        main()
    except AssertionError as exc:
        print(f"FAIL: {exc}", file=sys.stderr)
        sys.exit(1)
    except Exception as exc:  # noqa: BLE001
        print(f"ERROR: {exc}", file=sys.stderr)
        sys.exit(1)
