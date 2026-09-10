#!/usr/bin/env python3
"""Row-scan a PNG for true rendered INK bands.

A row counts as "ink" if any pixel in it differs from that row's own modal
(background) colour by more than THRESH in max-channel distance.  Reports
contiguous ink bands in PAGE coordinates (clip-origin + row).
"""
import sys
from collections import Counter
from PIL import Image

path = sys.argv[1]
origin = float(sys.argv[2])
thresh = int(sys.argv[3]) if len(sys.argv) > 3 else 12

im = Image.open(path).convert('RGB')
w, h = im.size
px = im.load()

rows = []
for y in range(h):
    counts = Counter(px[x, y] for x in range(w))
    bg, _ = counts.most_common(1)[0]
    ink_px = 0
    for x in range(w):
        p = px[x, y]
        if max(abs(p[0]-bg[0]), abs(p[1]-bg[1]), abs(p[2]-bg[2])) > thresh:
            ink_px += 1
    rows.append((y, bg, ink_px))

# contiguous ink bands
bands = []
cur = None
for y, bg, n in rows:
    if n > 0:
        if cur is None:
            cur = [y, y, n, 0]
        else:
            cur[1] = y
            cur[2] = max(cur[2], n)
    else:
        if cur is not None:
            bands.append(cur)
            cur = None
if cur is not None:
    bands.append(cur)

print(f"image {path} {w}x{h}  clip origin y={origin}  thresh={thresh}")
print("INK BANDS (page coords):")
prev_end = None
for b in bands:
    top = origin + b[0]
    bot = origin + b[1] + 1
    gap = ""
    if prev_end is not None:
        gap = f"   <-- {top - prev_end:.1f}px CLEAR above"
    print(f"  y {top:8.1f} .. {bot:8.1f}   height {bot-top:5.1f}  maxInkPx {b[2]:4d}{gap}")
    prev_end = bot

print()
print("BACKGROUND COLOUR CHANGES (page coords):")
last = None
for y, bg, n in rows:
    if bg != last:
        print(f"  y {origin + y:8.1f}   bg {bg}")
        last = bg
