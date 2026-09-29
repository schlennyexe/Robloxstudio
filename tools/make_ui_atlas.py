#!/usr/bin/env python3
"""
Zeichnet die UI-Bilder für Drop a Bot (glänzende Buttons, Platten, Icons) als Vektorgrafik,
rendert sie mit Chromium und packt sie in EINE Bilddatei: assets/ui/atlas.png (1024x1024).

Aufruf:  python3 tools/make_ui_atlas.py
Braucht: pip install pillow playwright  (Chromium liegt unter /opt/pw-browsers)
Ausgabe: assets/ui/atlas.png, assets/ui/atlas_rects.lua, assets/ui/atlas_preview.png
"""
import io, math, os, sys
from playwright.sync_api import sync_playwright
from PIL import Image

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "ui")
os.makedirs(OUT, exist_ok=True)
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"

# ---------------------------------------------------------------- Farben
def h2r(h):
    h = h.lstrip("#"); return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))
def r2h(c): return "#%02x%02x%02x" % tuple(max(0, min(255, round(v))) for v in c)
def mix(a, b, t):
    a, b = h2r(a), h2r(b); return r2h(tuple(a[i] + (b[i] - a[i]) * t for i in range(3)))
def light(c, t): return mix(c, "#ffffff", t)
def dark(c, t): return mix(c, "#000000", t)

MID = dict(green="#55dd3a", blue="#2fa8f7", purple="#9d5cf5", red="#f0404f", pink="#f556b2",
           gold="#ffbb1f", gray="#737a98", dark="#3d4256")

_uid = [0]
def uid():
    _uid[0] += 1; return f"u{_uid[0]}"

# ---------------------------------------------------------------- Geometrie-Helfer
def poly(points):
    area = sum(points[i][0] * points[(i + 1) % len(points)][1] - points[(i + 1) % len(points)][0] * points[i][1] for i in range(len(points)))
    if area < 0: points = points[::-1]
    return "M " + " L ".join(f"{x:.1f} {y:.1f}" for x, y in points) + " Z"

def rect_poly(cx, cy, w, h, ang=0):
    a = math.radians(ang); c, s = math.cos(a), math.sin(a)
    pts = [(-w / 2, -h / 2), (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)]
    return poly([(cx + x * c - y * s, cy + x * s + y * c) for x, y in pts])

def star_pts(cx, cy, R, r, n=5, rot=-90):
    pts = []
    for i in range(n * 2):
        rad = R if i % 2 == 0 else r
        a = math.radians(rot + i * 180 / n)
        pts.append((cx + rad * math.cos(a), cy + rad * math.sin(a)))
    return pts

def rrect(x, y, w, h, r):
    return (f"M {x + r} {y} H {x + w - r} A {r} {r} 0 0 1 {x + w} {y + r} V {y + h - r} A {r} {r} 0 0 1 {x + w - r} {y + h} "
            f"H {x + r} A {r} {r} 0 0 1 {x} {y + h - r} V {y + r} A {r} {r} 0 0 1 {x + r} {y} Z")

def bev(d, top, bot, hi, ink, wout=22, wr=10, dy=6, shadow=True):
    """Aufgesetzte Form: Schatten, dicke dunkle Kontur, helle Oberkante, Verlaufs-Körper."""
    i = uid()
    sh = (f'<path d="{d}" fill="{ink}" stroke="{ink}" stroke-width="{wout}" stroke-linejoin="round" '
          f'transform="translate(0,9)" opacity=".38" filter="url(#blur)"/>') if shadow else ""
    return f'''<defs><linearGradient id="g{i}" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset="1" stop-color="{bot}"/></linearGradient>
<mask id="m{i}" maskUnits="userSpaceOnUse" x="-50" y="-50" width="400" height="400"><path d="{d}" fill="#fff" stroke="#fff" stroke-width="{wr}" stroke-linejoin="round"/></mask></defs>
{sh}<path d="{d}" fill="{ink}" stroke="{ink}" stroke-width="{wout}" stroke-linejoin="round"/>
<path d="{d}" fill="{hi}" stroke="{hi}" stroke-width="{wr}" stroke-linejoin="round"/>
<g mask="url(#m{i})"><path d="{d}" fill="url(#g{i})" stroke="url(#g{i})" stroke-width="{wr}" stroke-linejoin="round" transform="translate(0,{dy})"/></g>'''

ROOT_DEFS = '''<defs><filter id="blur" x="-30%" y="-30%" width="160%" height="160%"><feGaussianBlur stdDeviation="3.2"/></filter></defs>'''

def svg_wrap(w, h, vw, vh, body):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {vw} {vh}" width="{w}" height="{h}">{ROOT_DEFS}{body}</svg>')

# ---------------------------------------------------------------- Kachel (quadratischer Knopf)
def tile_body(mid, icon):
    top, hi = light(mid, .62), light(mid, .30)
    rim_t, rim_b = dark(mid, .02), dark(mid, .42)
    base, ink, deep = dark(mid, .58), dark(mid, .82), dark(mid, .5)
    return f'''<defs>
<linearGradient id="rim" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{rim_t}"/><stop offset="1" stop-color="{rim_b}"/></linearGradient>
<linearGradient id="face" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset=".38" stop-color="{hi}"/><stop offset="1" stop-color="{mid}"/></linearGradient>
<linearGradient id="shade" x1="0" y1="0" x2="0" y2="1"><stop offset=".5" stop-color="{deep}" stop-opacity="0"/><stop offset="1" stop-color="{deep}" stop-opacity=".6"/></linearGradient>
<linearGradient id="gl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".95"/><stop offset="1" stop-color="#fff" stop-opacity=".06"/></linearGradient>
<radialGradient id="glow" cx=".5" cy="1.05" r=".75"><stop offset="0" stop-color="{light(mid, .75)}" stop-opacity=".75"/><stop offset="1" stop-color="{light(mid, .75)}" stop-opacity="0"/></radialGradient>
<clipPath id="inner"><rect x="22" y="16" width="212" height="200" rx="42"/></clipPath></defs>
<rect x="10" y="20" width="236" height="226" rx="52" fill="{base}" stroke="{ink}" stroke-width="8"/>
<rect x="10" y="6" width="236" height="226" rx="52" fill="url(#rim)" stroke="{ink}" stroke-width="8"/>
<rect x="22" y="16" width="212" height="200" rx="42" fill="url(#face)"/>
<g clip-path="url(#inner)">
 <rect x="22" y="16" width="212" height="200" fill="url(#shade)"/>
 <rect x="22" y="120" width="212" height="96" fill="url(#glow)"/>
 <path d="M 22 16 H 234 V 90 Q 128 128 22 90 Z" fill="url(#gl)"/>
</g>
<rect x="24" y="18" width="208" height="196" rx="40" fill="none" stroke="#fff" stroke-opacity=".38" stroke-width="3"/>
{icon}
<circle cx="50" cy="44" r="8" fill="#fff" opacity=".95"/><circle cx="70" cy="31" r="4" fill="#fff" opacity=".9"/><circle cx="33" cy="64" r="3" fill="#fff" opacity=".8"/>'''

# ---------------------------------------------------------------- Icons (Mitte ca. 128,102; unten 40 px frei für die Beschriftung)
def ico_upgrades(mid):
    ink, hi = dark(mid, .82), light(mid, .78)
    def chev(y0):
        return f"M 52 {y0 + 50} L 128 {y0} L 204 {y0 + 50} L 204 {y0 + 80} L 128 {y0 + 30} L 52 {y0 + 80} Z"
    return bev(chev(84), "#35b03a", "#146b26", hi, ink) + bev(chev(28), "#3fbf3c", "#16752a", hi, ink)

def ico_quests(mid):
    ink = dark(mid, .8)
    board = bev(rrect(78, 44, 100, 126, 14), "#ffffff", "#c9dff5", "#ffffff", ink, wout=20, wr=8)
    clip = bev(rrect(104, 32, 48, 26, 10), "#ffd45a", "#e08a00", "#fff0a8", ink, wout=18, wr=8, shadow=False)
    rows = ""
    for i, y in enumerate((84, 110, 136)):
        rows += f'<path d="M 92 {y + 2} l 8 9 l 16 -19" fill="none" stroke="{ink}" stroke-width="15" stroke-linecap="round" stroke-linejoin="round"/>'
        rows += f'<path d="M 92 {y + 2} l 8 9 l 16 -19" fill="none" stroke="#3bd35a" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"/>'
        rows += f'<rect x="124" y="{y - 5}" width="40" height="11" rx="5.5" fill="#8fb0d6"/>'
    return board + clip + rows

def ico_research(mid):
    ink = dark(mid, .82)
    flask = "M 108 40 H 148 V 92 L 190 158 Q 200 176 180 176 H 76 Q 56 176 66 158 L 108 92 Z"
    body = bev(flask, "#ffffff", "#e3d3ff", "#ffffff", ink, wout=22, wr=9)
    liquid = ('<defs><clipPath id="fl"><path d="M 108 40 H 148 V 92 L 190 158 Q 200 176 180 176 H 76 Q 56 176 66 158 L 108 92 Z"/></clipPath>'
              '<linearGradient id="lq" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#b8ff8a"/><stop offset="1" stop-color="#2bd66c"/></linearGradient></defs>'
              '<g clip-path="url(#fl)"><path d="M 40 122 Q 84 108 128 122 T 216 122 V 190 H 40 Z" fill="url(#lq)"/></g>')
    bubbles = '<circle cx="112" cy="146" r="8" fill="#fff" opacity=".95"/><circle cx="142" cy="132" r="5" fill="#fff" opacity=".9"/><circle cx="150" cy="156" r="6" fill="#fff" opacity=".9"/>'
    lip = bev(rrect(98, 30, 60, 16, 8), "#7b4de0", "#4a2a9c", "#c4a4ff", ink, wout=16, wr=6, shadow=False)
    return body + liquid + bubbles + lip

def ico_shop(mid):
    ink = dark(mid, .82)
    handle = "M 98 92 C 98 40 158 40 158 92"
    h = (f'<path d="{handle}" fill="none" stroke="{ink}" stroke-width="30" stroke-linecap="round"/>'
         f'<path d="{handle}" fill="none" stroke="#ffe3a0" stroke-width="15" stroke-linecap="round"/>')
    bag = bev("M 66 84 H 190 L 202 160 Q 203 176 187 176 H 69 Q 53 176 54 160 Z", "#fff6df", "#ffc987", "#ffffff", ink, wout=20, wr=8)
    star = bev(poly(star_pts(128, 132, 26, 12)), "#ffe25e", "#ff9d14", "#fff6b0", "#7a3a00", wout=10, wr=4, dy=3, shadow=False)
    return h + bag + star

def arc_arrow(cx, cy, r, a0, a1, w):
    def pt(rad, a): return (cx + rad * math.cos(math.radians(a)), cy + rad * math.sin(math.radians(a)))
    ro, ri = r + w / 2, r - w / 2
    p0o, p1o, p1i, p0i = pt(ro, a0), pt(ro, a1), pt(ri, a1), pt(ri, a0)
    large = 1 if (a1 - a0) % 360 > 180 else 0
    body = (f"M {p0o[0]:.1f} {p0o[1]:.1f} A {ro} {ro} 0 {large} 1 {p1o[0]:.1f} {p1o[1]:.1f} L {p1i[0]:.1f} {p1i[1]:.1f} "
            f"A {ri} {ri} 0 {large} 0 {p0i[0]:.1f} {p0i[1]:.1f} Z")
    tx, ty = -math.sin(math.radians(a1)), math.cos(math.radians(a1))
    bx, by = pt(r, a1)
    nx, ny = math.cos(math.radians(a1)), math.sin(math.radians(a1))
    hw = w * 1.12
    head = poly([(bx + nx * hw, by + ny * hw), (bx + tx * hw * 1.45, by + ty * hw * 1.45), (bx - nx * hw, by - ny * hw)])
    return body + " " + head

def ico_rebirth(mid):
    ink = dark(mid, .8)
    d = arc_arrow(128, 100, 52, 196, 306, 24) + " " + arc_arrow(128, 100, 52, 16, 126, 24)
    return bev(d, "#ffffff", "#ffd3ee", "#ffffff", ink, wout=20, wr=6)

def ico_index(mid):
    ink = dark(mid, .85)
    pages = bev(rrect(90, 46, 96, 122, 10), "#fffdf2", "#eadfb8", "#ffffff", ink, wout=20, wr=6, shadow=True)
    cover = bev(rrect(72, 40, 100, 130, 14), "#3e86f0", "#1a3fa6", "#a9d0ff", ink, wout=20, wr=8, shadow=False)
    spine = '<rect x="80" y="52" width="9" height="106" rx="4.5" fill="#fff" opacity=".28"/>'
    star = bev(poly(star_pts(126, 100, 26, 12)), "#ffe25e", "#ff9d14", "#fff6b0", "#6a3200", wout=10, wr=4, dy=3, shadow=False)
    ribbon = bev("M 140 32 H 160 V 84 L 150 76 L 140 84 Z", "#ff6a7a", "#d51f38", "#ffc0c8", ink, wout=12, wr=4, dy=3, shadow=False)
    return pages + cover + spine + star + ribbon

def ico_close(mid):
    ink = dark(mid, .8)
    d = rect_poly(128, 108, 122, 38, 45) + " " + rect_poly(128, 108, 122, 38, -45)
    return bev(d, "#ffffff", "#ffd6da", "#ffffff", ink, wout=22, wr=12)

def ico_plus(mid):
    ink = dark(mid, .78)
    d = rect_poly(128, 108, 116, 38, 0) + " " + rect_poly(128, 108, 116, 38, 90)
    return bev(d, "#ffffff", "#fff0c0", "#ffffff", ink, wout=22, wr=12)

# ---------------------------------------------------------------- Platten (breite Knöpfe / Karten)
def plate_body(w, h, mid):
    top, hi = light(mid, .6), light(mid, .28)
    rim_t, rim_b = dark(mid, .02), dark(mid, .42)
    base, ink, deep = dark(mid, .58), dark(mid, .82), dark(mid, .5)
    st, dep = h * .04, h * .10
    fh = h - dep - st * 1.6           # Höhe der Oberfläche
    x0, y0, fw = st * 1.0, st * .9, w - st * 2
    rx = min(fh * .34, fw / 2)
    ins = h * .075
    return f'''<defs>
<linearGradient id="rim" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{rim_t}"/><stop offset="1" stop-color="{rim_b}"/></linearGradient>
<linearGradient id="face" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{top}"/><stop offset=".4" stop-color="{hi}"/><stop offset="1" stop-color="{mid}"/></linearGradient>
<linearGradient id="shade" x1="0" y1="0" x2="0" y2="1"><stop offset=".5" stop-color="{deep}" stop-opacity="0"/><stop offset="1" stop-color="{deep}" stop-opacity=".55"/></linearGradient>
<linearGradient id="gl" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".9"/><stop offset="1" stop-color="#fff" stop-opacity=".05"/></linearGradient>
<clipPath id="inner"><rect x="{x0 + ins}" y="{y0 + ins}" width="{fw - 2 * ins}" height="{fh - 2 * ins}" rx="{rx - ins * .7}"/></clipPath></defs>
<rect x="{x0}" y="{y0 + dep}" width="{fw}" height="{fh}" rx="{rx}" fill="{base}" stroke="{ink}" stroke-width="{st}"/>
<rect x="{x0}" y="{y0}" width="{fw}" height="{fh}" rx="{rx}" fill="url(#rim)" stroke="{ink}" stroke-width="{st}"/>
<rect x="{x0 + ins}" y="{y0 + ins}" width="{fw - 2 * ins}" height="{fh - 2 * ins}" rx="{rx - ins * .7}" fill="url(#face)"/>
<g clip-path="url(#inner)">
 <rect x="{x0 + ins}" y="{y0 + ins}" width="{fw - 2 * ins}" height="{fh - 2 * ins}" fill="url(#shade)"/>
 <rect x="{x0 + ins}" y="{y0 + ins}" width="{fw - 2 * ins}" height="{(fh - 2 * ins) * .46}" fill="url(#gl)"/>
</g>
<rect x="{x0 + ins + 1}" y="{y0 + ins + 1}" width="{fw - 2 * ins - 2}" height="{fh - 2 * ins - 2}" rx="{rx - ins * .7}" fill="none" stroke="#fff" stroke-opacity=".32" stroke-width="{h * .02}"/>
<circle cx="{x0 + ins + rx * .7}" cy="{y0 + ins + h * .075}" r="{h * .035}" fill="#fff" opacity=".9"/>'''

# ---------------------------------------------------------------- kleine Symbole (128x128)
def small_nut():
    ink, fill = "#5a3200", "#ffc42e"
    pts = [(64 + 52 * math.cos(math.radians(a)), 64 + 52 * math.sin(math.radians(a))) for a in range(0, 360, 60)]
    d = poly(pts)
    b = bev(d, "#ffe98a", "#f09000", "#fff8c8", ink, wout=16, wr=8, dy=5)
    hole = f'<circle cx="64" cy="64" r="20" fill="{dark("#f09000", .55)}" stroke="{ink}" stroke-width="5"/><circle cx="64" cy="64" r="14" fill="{dark("#f09000", .7)}"/>'
    return b + hole

def small_gear():
    ink = dark(MID["purple"], .82)
    pts = []
    for i in range(16):
        a0 = math.radians(i * 22.5)
        rad = 54 if i % 2 == 0 else 42
        pts.append((64 + rad * math.cos(a0 - .12), 64 + rad * math.sin(a0 - .12)))
        pts.append((64 + rad * math.cos(a0 + .12), 64 + rad * math.sin(a0 + .12)))
    b = bev(poly(pts), "#d9beff", "#7a44de", "#f1e6ff", ink, wout=14, wr=6, dy=5)
    hole = f'<circle cx="64" cy="64" r="17" fill="{dark(MID["purple"], .6)}" stroke="{ink}" stroke-width="5"/>'
    return b + hole

def heart(cx, cy, ang, sc=1.0):
    """Herz-Blatt, Spitze in (cx,cy), zeigt in Richtung ang (Grad)."""
    base = [("M", [(0, 0)]), ("C", [(-16, -8), (-27, -30), (-15, -42)]), ("C", [(-7, -50), (0, -43), (0, -36)]),
            ("C", [(0, -43), (7, -50), (15, -42)]), ("C", [(27, -30), (16, -8), (0, 0)])]
    a = math.radians(ang); c, sn = math.cos(a), math.sin(a)
    def tf(p): return (cx + (p[0] * c - p[1] * sn) * sc, cy + (p[0] * sn + p[1] * c) * sc)
    out = ""
    for cmd, pts in base:
        out += cmd + " " + " ".join(f"{tf(p)[0]:.1f} {tf(p)[1]:.1f}" for p in pts) + " "
    return out + "Z "

def small_clover():
    ink = "#0d3a14"
    leaves = "".join(heart(64, 64, ang, 1.02) for ang in (0, 90, 180, 270))
    stem = "M 62 70 Q 64 100 88 118 L 94 110 Q 74 98 68 70 Z"
    veins = "".join(f'<path d="M 64 64 L {64 + 26 * math.cos(math.radians(a - 90)):.1f} {64 + 26 * math.sin(math.radians(a - 90)):.1f}" stroke="#1d7a2a" stroke-width="3.5" stroke-linecap="round" opacity=".55"/>' for a in (0, 90, 180, 270))
    return (bev(stem, "#5fd04a", "#2a8a2c", "#c4ff9a", ink, wout=10, wr=4, dy=2, shadow=False)
            + bev(leaves, "#a8f56e", "#25a238", "#e6ffc8", ink, wout=14, wr=8, dy=6) + veins)

def small_lock():
    ink = "#4a2c00"
    shackle = '<path d="M 40 60 V 42 Q 40 16 64 16 Q 88 16 88 42 V 60" fill="none" stroke="{i}" stroke-width="24" stroke-linecap="round"/><path d="M 40 60 V 42 Q 40 16 64 16 Q 88 16 88 42 V 60" fill="none" stroke="#dfe6f2" stroke-width="12" stroke-linecap="round"/>'.replace("{i}", ink)
    body = bev(rrect(24, 54, 80, 62, 14), "#ffe36a", "#f0980e", "#fff8c0", ink, wout=14, wr=6, dy=5)
    key = f'<circle cx="64" cy="82" r="8" fill="{ink}"/><rect x="60" y="84" width="8" height="18" rx="4" fill="{ink}"/>'
    return shackle + body + key

def small_glint():
    return '<path d="M 64 4 Q 68 60 124 64 Q 68 68 64 124 Q 60 68 4 64 Q 60 60 64 4 Z" fill="#fff"/><circle cx="64" cy="64" r="10" fill="#fff"/>'

def small_star():
    return bev(poly(star_pts(64, 66, 54, 24)), "#fff08a", "#ff9d14", "#fffbd0", "#6a3200", wout=14, wr=8, dy=5)

# ---------------------------------------------------------------- Bauplan des Atlas
TILE = 224
SPRITES = [  # name, x, y, w, h, svg-body(vw,vh)
]
def tile(name, x, y, colour, icon, size=TILE):
    SPRITES.append((name, x, y, size, size, svg_wrap(size, size, 256, 256, tile_body(MID[colour], icon(MID[colour])))))
def plate(name, x, y, w, h, colour):
    SPRITES.append((name, x, y, w, h, svg_wrap(w, h, w, h, plate_body(w, h, MID[colour]))))
def small(name, x, y, fn):
    SPRITES.append((name, x, y, 128, 128, svg_wrap(128, 128, 128, 128, fn())))

# --- 3D-Icons (ohne Platte), siehe tools/icons3d.py. name: (x, y, Größe, Konturfarbe)
ICONS3D = {
    "upgrades": (0, 0, 224, "#0d3a14"),
    "aufgaben": (224, 0, 224, "#0c2a5c"),
    "forschung": (448, 0, 224, "#2a1060"),
    "shop": (672, 0, 224, "#5a0a18"),
    "rebirth": (0, 224, 224, "#5a0f34"),
    "index": (224, 224, 224, "#0c2a66"),
    "teleport": (704, 224, 192, "#0c2a66"),
    "nut": (896, 0, 128, "#5a3200"),
    "gear": (896, 128, 128, "#2a1060"),
    "clover": (896, 256, 128, "#0d3a14"),
    "lock": (576, 448, 128, "#4a2c00"),
    "star": (832, 448, 128, "#5a3200"),
    "drop": (0, 448, 192, "#08425a"),
    "potion_g": (192, 448, 128, "#0d3a14"),
    "potion_y": (320, 448, 128, "#5a3200"),
    "potion_p": (448, 448, 128, "#3a1060"),
    "hand": (448, 352, 96, "#20242f"),
}
# --- Bots (zweite Bilddatei atlas_bots.png), Konturfarbe = dunkle Seltenheitsfarbe
BOTS = {
    "bot_toaster": "#2a3040", "bot_wecker": "#0d4a2a", "bot_katze": "#0c3a5c", "bot_feuerwehr": "#2a1060",
    "bot_drache": "#5a3200", "bot_samurai": "#5a0a18", "bot_satellit": "#5a4a10", "bot_prototyp": "#4a0a5a",
    "bot_staubsauger": "#2a3040", "bot_gluehbirne": "#2a3040",
    "bot_gameboy": "#0d4a2a", "bot_amboss": "#0d4a2a",
    "bot_eule": "#0c3a5c", "bot_hund": "#0c3a5c",
    "bot_bagger": "#2a1060", "bot_windrad": "#2a1060",
    "bot_zauberer": "#5a3200", "bot_magnet": "#5a3200",
    "bot_hacker": "#5a0a18", "bot_schmiedemech": "#5a0a18",
    "bot_astronaut": "#5a4a10", "bot_sonne": "#5a4a10",
    "bot_kikern": "#4a0a5a", "bot_zeitwaechter": "#4a0a5a",
}
# --- Upgrade-Symbole (ebenfalls in atlas_bots.png)
UPS = {
    "up_kerne": "#08425a", "up_tempo": "#7a3a00", "up_glueck": "#0d3a14", "up_reihen": "#1a2a6a",
    "up_plaetze": "#6a3200", "up_planGlueck": "#0c2a5c", "up_werkzeug": "#2a3040", "up_scanner": "#5a3200",
    "up_schnellwurf": "#5a0a18", "up_sockel": "#232a55", "up_splitter": "#08425a", "up_goldpin": "#5a3200",
}
# --- SVG-Platten und Symbole
tile("close", 448, 224, "red", ico_close, 128)
tile("plus", 576, 224, "gold", ico_plus, 128)
small("glint", 704, 448, small_glint)
plate("gold2", 0, 640, 256, 128, "gold")
plate("gray2", 256, 640, 256, 128, "gray")
plate("green2", 512, 640, 256, 128, "green")
plate("blue2", 768, 640, 256, 128, "blue")
plate("green4", 0, 768, 512, 128, "green")
plate("dark4", 512, 768, 512, 128, "dark")
plate("gray4", 0, 896, 512, 128, "gray")
plate("gold4", 512, 896, 512, 128, "gold")

def main():
    atlas = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    with sync_playwright() as p:
        br = p.chromium.launch(executable_path=CHROME, args=["--no-sandbox"])
        ctx = br.new_context(device_scale_factor=3)
        page = ctx.new_page()
        for name, x, y, w, h, svg in SPRITES:
            page.set_viewport_size({"width": w, "height": h})
            page.set_content(f'<html><body style="margin:0;background:transparent">{svg}</body></html>')
            png = page.screenshot(omit_background=True, clip={"x": 0, "y": 0, "width": w, "height": h})
            im = Image.open(io.BytesIO(png)).convert("RGBA").resize((w, h), Image.LANCZOS)
            atlas.alpha_composite(im, (x, y))
        br.close()
    sys.path.insert(0, os.path.dirname(__file__))
    import icons3d
    LABELED = {"upgrades", "aufgaben", "forschung", "shop", "rebirth", "index", "teleport", "drop"}   # unten bleibt Platz für die Beschriftung
    ims = icons3d.render({n: (((v[3], 0.88, 0.1) if n == "drop" else (v[3], 0.75, 0.17)) if n in LABELED else v[3]) for n, v in ICONS3D.items()}, 256, fill=0.87)
    for n, (x, y, sz, _) in ICONS3D.items():
        atlas.alpha_composite(ims[n].resize((sz, sz), Image.LANCZOS), (x, y))
    atlas.save(os.path.join(OUT, "atlas.png"), optimize=True)
    with open(os.path.join(OUT, "atlas_rects.lua"), "w", encoding="utf8") as f:
        f.write("local SPR = {\n")
        for name, x, y, w, h, _ in SPRITES:
            f.write(f'\t{name} = {{ {x}, {y}, {w}, {h} }},\n')
        for n, (x, y, sz, _) in ICONS3D.items():
            f.write(f'\t{n} = {{ {x}, {y}, {sz}, {sz} }},\n')
        f.write("}\n")
    # --- zweite Bilddatei: Bots und Upgrade-Symbole (6 pro Reihe, 160 px)
    ims = icons3d.render({n: c for n, c in {**BOTS, **UPS}.items()}, 256, fill=0.87)
    bots = Image.new("RGBA", (1024, 1024), (0, 0, 0, 0))
    with open(os.path.join(OUT, "atlas_bots_rects.lua"), "w", encoding="utf8") as f:
        f.write("local BSPR = {\n")
        for i, n in enumerate({**BOTS, **UPS}):
            x, y = (i % 6) * 160, (i // 6) * 160
            bots.alpha_composite(ims[n].resize((160, 160), Image.LANCZOS), (x, y))
            f.write(f"\t{n} = {{ {x}, {y}, 160, 160 }},\n")
        f.write("}\n")
    bots.save(os.path.join(OUT, "atlas_bots.png"), optimize=True)
    for tag, bg in (("grass", (120, 200, 70, 255)),):
        prev = Image.new("RGBA", (1024, 1024), bg); prev.alpha_composite(atlas)
        prev.convert("RGB").save(os.path.join(OUT, f"atlas_preview_{tag}.png"))
    print("fertig:", os.path.abspath(OUT))

if __name__ == "__main__":
    main()
