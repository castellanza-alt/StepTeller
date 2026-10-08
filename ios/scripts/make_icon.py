#!/usr/bin/env python3
"""Disegna l'icona 1024×1024 (RGB, senza trasparenza): tappeto di Step Teller su fondo antracite
caldo con nastro teal. Usa gli stessi path SVG dell'app. Esegui: python3 ios/scripts/make_icon.py"""
import re
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parents[1] / 'App/Assets.xcassets/AppIcon.appiconset/icon-1024.png'
S = 2048  # supercampionamento 2x

def bez(p0, p1, p2, p3, n=24):
    return [tuple((1-t)**3*p0[i] + 3*(1-t)**2*t*p1[i] + 3*(1-t)*t**2*p2[i] + t**3*p3[i] for i in (0, 1))
            for t in [k/n for k in range(1, n+1)]]

def flatten(d):
    toks = re.findall(r'[MLCZ]|-?\d+\.?\d*', d); i = 0; pts = []; cur = (0, 0)
    num = lambda: float(toks[i])
    while i < len(toks):
        c = toks[i]; i += 1
        if c in 'ML':
            cur = (float(toks[i]), float(toks[i+1])); i += 2; pts.append(cur)
        elif c == 'C':
            a = [(float(toks[i+k]), float(toks[i+k+1])) for k in (0, 2, 4)]; i += 6
            pts += bez(cur, *a); cur = a[2]
    return pts

PATHS = {
 'frame': "M40 150 L290 140 C302 139.5 306 146 306 152 L306 154 C306 161 300 165 292 165 L48 168 C38 168.4 32 162 32 156 C32 152 36 150.2 40 150 Z",
 'belt': "M46 147.4 L286 137.8 L286.6 143.6 L46.6 153 Z",
 'frame2': "M290 141 C300 140.6 304 146 304 152 L304 154 C304 160 299 163.6 292 163.8 L288 164 L288 141.2 Z",
 'post': "M282 140 C286 117 293 78 302 44",
 'rail': "M298 68 C268 68 240 72 232 80 C226 87 230 94 240 94 C258 93.5 276 93 293 92.5",
}

def main():
    # fondo antracite caldo con leggera sfumatura
    img = Image.new('RGB', (S, S))
    px = img.load()
    for y in range(S):
        for x in range(S):
            t = (x + y) / (2 * S)
            px[x, y] = (int(46 - 18*t), int(44 - 18*t), int(41 - 18*t))
    # alone teal dietro al tappeto
    glow = Image.new('RGB', (S, S), (0, 0, 0)); g = ImageDraw.Draw(glow)
    g.ellipse([S*0.18, S*0.38, S*0.82, S*0.78], fill=(26, 58, 54))
    glow = glow.filter(ImageFilter.GaussianBlur(S*0.07))
    img = Image.blend(img, Image.composite(glow, img, Image.new('L', (S, S), 255)), 0.0)
    from PIL import ImageChops
    img = ImageChops.add(img, glow)
    d = ImageDraw.Draw(img)
    # tappeto: viewBox 360×200 → area centrale
    k = S * 0.64 / 274; ox = S / 2 - 169 * k; oy = S / 2 - 104 * k
    T = lambda pts: [(ox + x*k, oy + y*k) for x, y in pts]
    FRAME, FRAME2, BELT, ACC = (214, 212, 206), (154, 152, 147), (185, 183, 177), (140, 203, 191)
    d.polygon(T(flatten(PATHS['frame'])), fill=FRAME)
    d.polygon(T(flatten(PATHS['belt'])), fill=BELT)
    # nastro: tratteggio teal
    (x0, y0), (x1, y1) = (282, 139.2), (50, 148.6)
    n = 17
    for j in range(n):
        t = j / (n - 1); x = x0 + (x1-x0)*t; y = y0 + (y1-y0)*t
        r = 2.6 * k
        cx, cy = ox + x*k, oy + y*k
        d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=ACC)
    d.polygon(T(flatten(PATHS['frame2'])), fill=FRAME2)
    for c in [(46, 170), (268, 168)]:
        cx, cy = ox + c[0]*k, oy + c[1]*k; r = 3.6*k
        d.ellipse([cx-r, cy-r, cx+r, cy+r], fill=FRAME2)
    w = int(2.8 * k)
    d.line(T(flatten("M282 140 C286 117 293 78 302 44")), fill=FRAME, width=w, joint='curve')
    d.line(T([(298, 68)] + flatten(PATHS['rail'])[0:]), fill=FRAME, width=w, joint='curve')
    # console con schermo teal
    con = Image.new('RGBA', (S, S), (0, 0, 0, 0)); cd = ImageDraw.Draw(con)
    cd.rounded_rectangle([ox+270*k, oy+33*k, ox+330*k, oy+46*k], radius=6.5*k, fill=FRAME + (255,))
    cd.rounded_rectangle([ox+277*k, oy+36.5*k, ox+323*k, oy+42.5*k], radius=3*k, fill=ACC + (255,))
    con = con.rotate(8, center=(ox+300*k, oy+40*k), resample=Image.BICUBIC)
    img.paste(con, (0, 0), con)
    img = img.resize((1024, 1024), Image.LANCZOS).convert('RGB')
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, 'PNG')
    print('Scritto', OUT)

main()
