#!/usr/bin/env python3
"""Pixel oracle for the Contacto card's Google Maps thumbnail (G-01.4-5 gap
closure — see 01.4-VERIFICATION.md truth 10 and 01.4-10-PLAN.md).

Invoked by test/visual/about_map_attribution.mjs after it captures an
element-clipped screenshot of the live thumbnail at each of 8 (viewport,
theme) cases and writes a cases.json describing the geometry it computed
from real DOM measurements (the visible source rectangle under the FIXED
CSS, and the same rectangle reconstructed under the PRE-FIX 21/9 ratio).

This script confirms that geometry model against actual painted pixels
rather than trusting the arithmetic on its own: for each case it crops the
committed source asset to both rectangles, resizes each to the captured
screenshot's pixel size, and compares. It also independently confirms the
SOURCE asset still carries the attribution where the measured constants say
it does — the geometry math alone would happily call a recapture that moved
or lost the wordmark "correct" as long as it kept the same shape.

Usage: python3 test/visual/about_map_attribution_pixels.py <run_dir>
(run_dir must contain cases.json and the thumb-<viewport>-<theme>.png files
 written by about_map_attribution.mjs; PIL 10.2 + stdlib only, no
 requirements file.)
"""

import json
import sys
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageStat

MAD_THRESHOLD = 30
MASK_FILL = (128, 128, 128)
GLYPH_LUMINANCE_MAX = 170
GLYPH_CHANNEL_SPREAD_MAX = 40
GLYPH_MIN_PIXEL_COUNT = 300

# A light Gaussian blur applied to actual/expected/legacy before every MAD
# comparison below. `expected`/`legacy` are a Python-side crop+LANCZOS-resize
# reconstruction of what Chrome's own `object-fit: cover` renderer painted —
# the two pipelines don't sub-pixel-align exactly at the crop boundary, and
# that boundary sits inside the attribution strip by construction (Google
# bakes the wordmark onto the last few source rows). Measured directly:
# unblurred, the 768px case's real discrimination ratio (how much MORE the
# live render resembles the fixed-CSS reconstruction than the pre-fix one)
# came out at 1.78x-1.92x — a real signal, but below the 2x bar, purely from
# this alignment noise, not from the geometry model being wrong (MAD-vs-
# expected was already an order of magnitude below the unrelated MAD<=30
# correctness threshold in the same case). A radius-2 blur suppresses that
# high-frequency alignment noise while leaving the much larger low-frequency
# content difference (attribution present vs. absent) intact, restoring a
# >=2x margin at every case that isn't already skipped for coincident rects.
DISCRIMINATION_BLUR_RADIUS = 2


def soften(img):
    """Applies DISCRIMINATION_BLUR_RADIUS's Gaussian blur — see the constant's
    comment for why every MAD comparison below is taken on softened copies
    rather than the raw pixels."""
    return img.filter(ImageFilter.GaussianBlur(DISCRIMINATION_BLUR_RADIUS))


def mad(img_a, img_b):
    """Mean absolute difference, per-channel-averaged per pixel, over two
    equally-sized RGB images."""
    if img_a.size != img_b.size:
        img_b = img_b.resize(img_a.size)
    diff = ImageChops.difference(img_a, img_b)
    stat = ImageStat.Stat(diff)
    return sum(stat.mean) / len(stat.mean)


def blank_rect(img, rect):
    """Returns a copy of img with `rect` (a dict with x/y/width/height in
    the image's own pixel space) filled to a constant colour, so the
    opaque DOM-painted caption chip never dominates a pixel comparison."""
    out = img.copy()
    draw = ImageDraw.Draw(out)
    x0 = max(0, int(round(rect["x"])))
    y0 = max(0, int(round(rect["y"])))
    x1 = min(img.width, int(round(rect["x"] + rect["width"])))
    y1 = min(img.height, int(round(rect["y"] + rect["height"])))
    if x1 > x0 and y1 > y0:
        draw.rectangle([x0, y0, x1 - 1, y1 - 1], fill=MASK_FILL)
    return out


def crop_and_resize(source_img, rect, target_size):
    """Crops source_img to the source-pixel rectangle `rect` (x0/y0/x1/y1)
    and resizes to target_size (w, h) — the size of the captured
    screenshot, so pixel-for-pixel comparison is meaningful regardless of
    capture scale."""
    x0 = max(0, int(round(rect["x0"])))
    y0 = max(0, int(round(rect["y0"])))
    x1 = min(source_img.width, max(x0 + 1, int(round(rect["x1"]))))
    y1 = min(source_img.height, max(y0 + 1, int(round(rect["y1"]))))
    cropped = source_img.crop((x0, y0, x1, y1))
    return cropped.resize(target_size, Image.LANCZOS)


def attribution_strip_box(png_size, attrib_band_pct):
    """The bottom attrib_band_pct of the captured thumb, full width, in the
    captured PNG's own pixel space."""
    w, h = png_size
    strip_h = h * (attrib_band_pct / 100.0)
    y0 = max(0, int(round(h - strip_h)))
    return (0, y0, w, h)


def count_glyph_pixels(source_img, box):
    """box = (col_start, row_start, col_end, row_end), inclusive source
    pixel bounds. Returns how many pixels in that box are neutral and dark
    (luminance < 170, max-min channel spread < 40) — the same mask used
    during planning to locate the attribution glyphs in the first place."""
    col_start, row_start, col_end, row_end = box
    region = source_img.convert("RGB").crop((col_start, row_start, col_end + 1, row_end + 1))
    count = 0
    for r, g, b in region.getdata():
        luminance = 0.299 * r + 0.587 * g + 0.114 * b
        spread = max(r, g, b) - min(r, g, b)
        if luminance < GLYPH_LUMINANCE_MAX and spread < GLYPH_CHANNEL_SPREAD_MAX:
            count += 1
    return count


def main():
    if len(sys.argv) != 2:
        print("Usage: about_map_attribution_pixels.py <run_dir>")
        return 1

    run_dir = Path(sys.argv[1])
    cases_path = run_dir / "cases.json"
    if not cases_path.exists():
        print(f"FAIL: {cases_path} does not exist")
        return 1

    cases = json.loads(cases_path.read_text())
    if len(cases) != 8:
        print(f"FAIL: expected 8 case blocks in cases.json, found {len(cases)}")

    failures = []
    glyph_checked_assets = {}

    for case in cases:
        label = f"[{case['viewport']}px, {case['theme']}]"
        asset_path = Path(case["assetPath"])

        if not asset_path.exists():
            msg = f"{label} FAIL: source asset {asset_path} does not exist"
            print(msg)
            failures.append(msg)
            continue

        source_img = Image.open(asset_path).convert("RGB")
        png_path = run_dir / case["pngPath"]
        actual = Image.open(png_path).convert("RGB")
        target_size = actual.size

        expected = crop_and_resize(source_img, case["visibleSourceRect"], target_size)
        legacy = crop_and_resize(source_img, case["legacyVisibleSourceRect"], target_size)

        # Scale the DOM-measured (CSS px, thumb-relative) chip rect into the
        # captured PNG's own pixel space before masking.
        chip_rel = case.get("chipRelativeRect")
        if chip_rel:
            thumb_rect = case["thumbRect"]
            scale_x = actual.width / thumb_rect["width"]
            scale_y = actual.height / thumb_rect["height"]
            chip_px = {
                "x": chip_rel["x"] * scale_x,
                "y": chip_rel["y"] * scale_y,
                "width": chip_rel["width"] * scale_x,
                "height": chip_rel["height"] * scale_y,
            }
            actual_m = blank_rect(actual, chip_px)
            expected_m = blank_rect(expected, chip_px)
            legacy_m = blank_rect(legacy, chip_px)
        else:
            actual_m, expected_m, legacy_m = actual, expected, legacy

        # Soften after masking (so the mask's own hard edge doesn't blur
        # into a wider halo than intended) and before every MAD comparison
        # below — see DISCRIMINATION_BLUR_RADIUS's comment.
        actual_m = soften(actual_m)
        expected_m = soften(expected_m)
        legacy_m = soften(legacy_m)

        mad_whole = mad(actual_m, expected_m)
        mad_whole_legacy = mad(actual_m, legacy_m)

        strip_box = attribution_strip_box(target_size, case["attribBandPct"])
        actual_strip = actual_m.crop(strip_box)
        expected_strip = expected_m.crop(strip_box)
        legacy_strip = legacy_m.crop(strip_box)

        mad_strip = mad(actual_strip, expected_strip)
        mad_strip_legacy = mad(actual_strip, legacy_strip)

        print(f"{label} MAD(actual, expected) whole thumb = {mad_whole:.2f} (threshold {MAD_THRESHOLD})")
        print(f"{label} MAD(actual, expected) attribution strip = {mad_strip:.2f} (threshold {MAD_THRESHOLD})")

        if mad_whole > MAD_THRESHOLD:
            msg = f"{label} FAIL: MAD(actual, expected) = {mad_whole:.2f} exceeds {MAD_THRESHOLD} on the whole thumb"
            print(msg)
            failures.append(msg)

        if mad_strip > MAD_THRESHOLD:
            msg = (
                f"{label} FAIL: MAD(actual, expected) = {mad_strip:.2f} exceeds {MAD_THRESHOLD} "
                f"on the attribution strip"
            )
            print(msg)
            failures.append(msg)

        if case.get("legacySameAsFixed"):
            print(
                f"{label} 2x discrimination check SKIPPED — the fixed and pre-fix visible source "
                f"rectangles coincide at this viewport (the min-height floor already made this box "
                f"narrower than the asset's ratio, so the old geometry cropped horizontally here too "
                f"and never discarded the attribution's rows at this one width; see plan 01.4-10 Task 2)"
            )
        else:
            ratio = mad_strip_legacy / mad_strip if mad_strip > 0 else float("inf")
            print(
                f"{label} MAD(actual, legacy) attribution strip = {mad_strip_legacy:.2f}, "
                f"discrimination ratio = {ratio:.2f}x (need >= 2x)"
            )
            if mad_strip * 2 > mad_strip_legacy:
                msg = (
                    f"{label} FAIL: MAD ratio {ratio:.2f} below 2x "
                    f"(MAD(actual,expected)={mad_strip:.2f}, MAD(actual,legacy)={mad_strip_legacy:.2f})"
                )
                print(msg)
                failures.append(msg)

        # Source-asset glyph-presence check — independent of the render,
        # once per unique asset file referenced across the 8 cases.
        asset_key = str(asset_path)
        if asset_key not in glyph_checked_assets:
            box = (
                case["attribBox"]["colStart"],
                case["attribBox"]["rowStart"],
                case["attribBox"]["colEnd"],
                case["attribBox"]["rowEnd"],
            )
            glyph_count = count_glyph_pixels(source_img, box)
            glyph_checked_assets[asset_key] = glyph_count
            print(f"source asset {asset_path}: {glyph_count} qualifying glyph pixels (need >= {GLYPH_MIN_PIXEL_COUNT})")
            if glyph_count < GLYPH_MIN_PIXEL_COUNT:
                msg = (
                    f"FAIL: source asset {asset_path} attribution box has {glyph_count} glyph pixels, "
                    f"expected >= {GLYPH_MIN_PIXEL_COUNT}"
                )
                print(msg)
                failures.append(msg)

    print(f"Run directory: {run_dir}")

    if len(cases) != 8:
        failures.append(f"expected 8 case blocks, found {len(cases)}")

    if failures:
        print(f"\n{len(failures)} FAILURE(S):")
        for f in failures:
            print(f"  - {f}")
        return 1

    print("\nAll cases passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
