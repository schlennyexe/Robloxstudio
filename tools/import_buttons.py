#!/usr/bin/env python3
"""
Schneidet die fertigen Button-Bilder (JPG auf weißem Hintergrund) frei und legt sie als PNG mit Transparenz in
assets/ui/buttons/ ab. tools/make_ui_atlas.py setzt diese Bilder danach in den Atlas.

Aufruf:  python3 tools/import_buttons.py  <Ordner mit den JPGs>
Braucht: pip install pillow numpy scipy
"""
import os, sys
import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, "..", "assets", "ui", "buttons")
MAXSIDE = 640           # gespeichert wird höchstens so groß (reicht für den Atlas)
BG_MIN, BG_RANGE = 150, 24   # "Hintergrund" = hell und fast farblos (Weiß und weiche Schatten)
WORK = 1400             # Arbeitsgröße (längste Seite)
# Einzelfälle: Lücken schließen (Kolbenhals ist im Original nur Glas ohne Rand) und dunkle Kontur nachziehen (Farbe, Breite bei 640 px)
CLOSE = {"ForschungButton": 14}
STRICT = {"ForschungButton": 9}     # Glasränder sind nur blass bläulich: Hintergrund muss hier wirklich farblos sein
OUTLINE = {"UpgradeButton": ("#0a3a12", 9), "AufgabenButton": ("#3a1a08", 6), "ForschungButton": ("#232a4a", 9)}

def add_outline(im, color, width):
    a = np.asarray(im.getchannel("A"), dtype=np.float32) / 255.0
    pad = int(width) + 4
    a = np.pad(a, pad)
    dist = ndimage.distance_transform_edt(a < 0.5)
    ring = np.clip(width + 0.5 - dist, 0, 1)
    rgb = np.array([int(color[i:i + 2], 16) for i in (1, 3, 5)], dtype=np.float32)
    base = np.zeros((*a.shape, 4), dtype=np.float32)
    base[..., :3] = rgb; base[..., 3] = np.maximum(ring, a) * 255.0
    under = Image.fromarray(base.astype(np.uint8), "RGBA")
    src = Image.new("RGBA", under.size, (0, 0, 0, 0)); src.paste(im, (pad, pad))
    under.alpha_composite(src)
    return under

def cutout(path):
    im = Image.open(path).convert("RGB")
    key = os.path.splitext(os.path.basename(path))[0]
    im.thumbnail((WORK, WORK), Image.LANCZOS)
    a = np.asarray(im, dtype=np.float32)
    mn, mx = a.min(axis=2), a.max(axis=2)
    bgish = (mn >= BG_MIN) & ((mx - mn) <= STRICT.get(key, BG_RANGE))
    lab, n = ndimage.label(bgish)
    border = set(np.unique(np.concatenate([lab[0], lab[-1], lab[:, 0], lab[:, -1]]))) - {0}
    bg = np.isin(lab, list(border))
    fg = ~bg
    fg = ndimage.binary_opening(fg, iterations=2)                          # Krümel weg
    lab2, n2 = ndimage.label(fg)                                            # nur der größte Körper (plus große Teile) bleibt
    if n2 > 1:
        sizes = ndimage.sum(fg, lab2, range(1, n2 + 1))
        keep = [i + 1 for i, sz in enumerate(sizes) if sz >= 0.02 * sizes.max()]
        fg = np.isin(lab2, keep)
    fg = ndimage.binary_fill_holes(fg)
    added = np.zeros_like(fg)
    if key in CLOSE:
        r = CLOSE[key]
        yy, xx = np.mgrid[-r:r + 1, -r:r + 1]
        disk = (xx * xx + yy * yy) <= r * r
        padded = np.pad(fg, r + 2)
        closed = ndimage.binary_closing(padded, structure=disk)[r + 2:-(r + 2), r + 2:-(r + 2)]
        closed = ndimage.binary_fill_holes(closed)
        added = closed & ~fg
        fg = closed
    # Randband: Anti-Aliasing gegen Weiß entmischen
    dist_in = ndimage.distance_transform_edt(fg)
    dist_out = ndimage.distance_transform_edt(~fg)
    core = dist_in > 4
    _, idx = ndimage.distance_transform_edt(~core, return_indices=True)
    inner = a[idx[0], idx[1]]                                               # nächste "sichere" Farbe
    band = (dist_in <= 4) | (dist_out <= 2)
    d = 255.0 - inner
    num = ((255.0 - a) * d).sum(axis=2)
    den = np.maximum((d * d).sum(axis=2), 1.0)
    alpha_band = np.clip(num / den, 0, 1)
    alpha = np.where(fg, 1.0, 0.0).astype(np.float32)
    # innen am Rand: weicher Verlauf; außen (bis 2 px): nur wenn wirklich Farbe da ist
    edge_in = fg & (dist_in <= 3) & ~ndimage.binary_dilation(added, iterations=2)
    alpha[edge_in] = np.clip(alpha_band[edge_in] * 1.15, 0, 1)
    edge_out = (~fg) & (dist_out <= 1.5)
    alpha[edge_out] = np.clip(alpha_band[edge_out] * 0.9, 0, 1) * (alpha_band[edge_out] > 0.25)
    rgb = np.where(band[..., None], inner, a)
    if added.any():                                                         # gefüllte Glasfläche: hell, leicht bläulich
        rgb[added] = np.minimum(rgb[added] * np.array([0.93, 0.96, 1.0]), 255)
        alpha[added] = 1.0
    out = np.dstack([np.clip(rgb, 0, 255), alpha * 255]).astype(np.uint8)
    res = Image.fromarray(out, "RGBA")
    bb = res.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox()
    res = res.crop(bb)
    res.thumbnail((MAXSIDE, MAXSIDE), Image.LANCZOS)
    if key in OUTLINE:
        res = add_outline(res, *OUTLINE[key])
        res = res.crop(res.getchannel("A").point(lambda v: 255 if v > 8 else 0).getbbox())
    return res

def main(src):
    os.makedirs(OUT, exist_ok=True)
    for name in sorted(os.listdir(src)):
        if not name.lower().endswith((".jpg", ".jpeg", ".png")):
            continue
        res = cutout(os.path.join(src, name))
        target = os.path.join(OUT, os.path.splitext(name)[0] + ".png")
        res.save(target, optimize=True)
        print(name, "->", os.path.basename(target), res.size)

if __name__ == "__main__":
    main(sys.argv[1])
