"""3D-Icons rendern (three.js in Chromium) und mit dicker, dunkler Kontur versehen."""
import base64, functools, http.server, io, os, threading
import numpy as np
from PIL import Image, ImageEnhance
from scipy import ndimage
from playwright.sync_api import sync_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
CHROME = "/opt/pw-browsers/chromium-1194/chrome-linux/chrome"
GAMMA, SAT, CONTRAST, OUTLINE = 1.32, 1.04, 1.12, 0.048   # Mitteltöne dunkler, Farben satt, Kontur dicker

def _serve():
    h = functools.partial(http.server.SimpleHTTPRequestHandler, directory=os.path.join(HERE, "render3d"))
    h.log_message = lambda *a, **k: None
    srv = http.server.ThreadingHTTPServer(("127.0.0.1", 0), h)
    threading.Thread(target=srv.serve_forever, daemon=True).start()
    return srv

def outline(im, color, width):
    """Dicke Kontur um die Silhouette (weich, kreisrund). im: RGBA, Größe beliebig."""
    a = np.asarray(im.getchannel("A"), dtype=np.float32) / 255.0
    dist = ndimage.distance_transform_edt(a < 0.5)
    ring = np.clip(width + 0.5 - dist, 0, 1)                    # 1 innerhalb 'width' Pixel
    base = np.zeros((*a.shape, 4), dtype=np.float32)
    rgb = np.array([int(color[i:i + 2], 16) for i in (1, 3, 5)], dtype=np.float32)
    base[..., :3] = rgb; base[..., 3] = np.maximum(ring, a) * 255.0
    under = Image.fromarray(base.astype(np.uint8), "RGBA")
    under.alpha_composite(im)
    return under

def render(names, size, fill=0.86, ol_width=None):
    """names: {name: Konturfarbe | (Konturfarbe, fill, yShift) | (Konturfarbe, fill, yShift, "crop")}.
    Liefert {name: RGBA-Image size x size} mit Kontur. Bei "crop" kommt das eng zugeschnittene Bild in voller Auflösung zurück."""
    srv = _serve(); out = {}
    port = srv.server_address[1]
    with sync_playwright() as p:
        b = p.chromium.launch(executable_path=CHROME, args=["--no-sandbox", "--use-angle=swiftshader", "--enable-unsafe-swiftshader", "--ignore-gpu-blocklist"])
        pg = b.new_page(viewport={"width": 512, "height": 512})
        errs = []
        pg.on("pageerror", lambda e: errs.append(str(e))); pg.on("console", lambda m: errs.append(m.text) if m.type == "error" else None)
        pg.goto(f"http://127.0.0.1:{port}/icons.html")
        pg.wait_for_function("window.__ready === true", timeout=30000)
        for name, spec in names.items():
            col, f, shift, *rest = spec if isinstance(spec, tuple) else (spec, fill, 0)
            crop = bool(rest and rest[0] == "crop")
            url = pg.evaluate("([n, f, y]) => window.renderIcon(n, f, y)", [name, f, shift])
            im = Image.open(io.BytesIO(base64.b64decode(url.split(",")[1]))).convert("RGBA")
            # Kontur auf hoher Auflösung, danach runterrechnen
            r, g, bch, al = im.split()
            # Farbstimmung: Mitteltöne abdunkeln (gegen Überbelichtung), Farben satt, klarer Kontrast
            arr = np.asarray(Image.merge("RGB", (r, g, bch)), dtype=np.float32) / 255.0
            arr = np.clip(arr, 0, 1) ** GAMMA
            rgb = Image.fromarray((arr * 255).astype(np.uint8), "RGB")
            rgb = ImageEnhance.Color(rgb).enhance(SAT)
            rgb = ImageEnhance.Contrast(rgb).enhance(CONTRAST)
            im = Image.merge("RGBA", (*rgb.split(), al))
            w = ol_width if ol_width is not None else OUTLINE * im.width
            im = outline(im, col, w)
            if crop:
                bb = im.getbbox()
                out[name] = im.crop((bb[0] - 2, bb[1] - 2, bb[2] + 2, bb[3] + 2))
            else:
                out[name] = im.resize((size, size), Image.LANCZOS)
        b.close()
    srv.shutdown()
    if errs: print("Browser-Meldungen:", errs[:5])
    return out
