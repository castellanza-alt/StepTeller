"""T-030: puts the new app screenshots (heart and bubble, <=10 km/h) into the store screenshots 01-03 of each
language, keeping titles, frames and layout of the approved ones. Transforms measured per image with SIFT."""
import cv2, numpy as np, math, sys
from pathlib import Path
ROOT = Path(sys.argv[1]); SHOTS = Path(sys.argv[2]); OUT = Path(sys.argv[3]); LANGS = sys.argv[4:]
SW, SH = 1290, 2796
DOWN = 475  # 02: how much lower the minutes box goes (composite px)
sift = cv2.SIFT_create(10000)

def fit(comp, src, src_box, comp_box):
    g = cv2.cvtColor(comp, cv2.COLOR_BGR2GRAY); sg = cv2.cvtColor(src, cv2.COLOR_BGR2GRAY)
    ms = np.zeros(sg.shape, np.uint8); x0, y0, x1, y1 = src_box; ms[y0:y1, x0:x1] = 255
    mc = np.zeros(g.shape, np.uint8); x0, y0, x1, y1 = comp_box; mc[y0:y1, x0:x1] = 255
    k1, d1 = sift.detectAndCompute(sg, ms); k2, d2 = sift.detectAndCompute(g, mc)
    good = [a for a, b in cv2.BFMatcher().knnMatch(d1, d2, k=2) if a.distance < 0.75 * b.distance]
    p1 = np.float32([k1[x.queryIdx].pt for x in good]); p2 = np.float32([k2[x.trainIdx].pt for x in good])
    M, inl = cv2.estimateAffinePartial2D(p1, p2, ransacReprojThreshold=2.0, maxIters=20000)
    return M, math.hypot(M[0, 0], M[1, 0]), math.degrees(math.atan2(M[1, 0], M[0, 0])), int(inl.sum())

def box_mask(box, M, shape, size=(1700, 3000)):
    """Composite-space alpha of a source-space box under M."""
    m = np.zeros((size[1], size[0]), np.float32); x0, y0, x1, y1 = box
    m[max(y0, 0):y1, max(x0, 0):x1] = 1
    off = np.float32([[1, 0, 0], [0, 1, 0]])
    return cv2.warpAffine(m, M, (shape[1], shape[0]), flags=cv2.INTER_LINEAR)

def outside(box, M, shape):
    """1 outside a source-space box (any coordinates, also negative) under M."""
    H, W = shape[:2]; Mi = cv2.invertAffineTransform(M)
    xs, ys = np.meshgrid(np.arange(W), np.arange(H)); sx = Mi[0, 0]*xs + Mi[0, 1]*ys + Mi[0, 2]; sy = Mi[1, 0]*xs + Mi[1, 1]*ys + Mi[1, 2]
    x0, y0, x1, y1 = box
    return 1 - ((sx >= x0) & (sx < x1) & (sy >= y0) & (sy < y1)).astype(np.float32)

def paste(comp, src, M, alpha):
    w = cv2.warpAffine(src, M, (comp.shape[1], comp.shape[0]), flags=cv2.INTER_AREA if M[0,0] < 1 else cv2.INTER_CUBIC)
    a = alpha[..., None]
    return (comp * (1 - a) + w * a).round().clip(0, 255).astype(np.uint8)

def check(tag, s, ang, n, s_exp, ang_exp):
    ok = abs(s - s_exp) < 0.01 and abs(ang - ang_exp) < 0.3 and n > 40
    print(f'  {tag}: scala {s:.4f} angolo {ang:+.2f} punti {n}' + ('' if ok else '  <-- DA CONTROLLARE'))
    if not ok: raise SystemExit(f'{tag}: trasformazione inattesa')

for L in LANGS:
    print(L); src = ROOT / 'store/screenshots' / L; sh = SHOTS / L; out = OUT / L; out.mkdir(parents=True, exist_ok=True)
    # 01: Home day 4 km/h in the phone
    c = cv2.imread(str(src / '01.jpg')); n = cv2.imread(str(sh / 'home-4kmh-day.png'))
    M, s, a, k = fit(c, n, (0, 170, SW, 1000), (0, 700, 1320, 2868)); check('01 schermo', s, a, k, 0.778, -2.0)
    c = paste(c, n, M, box_mask((3, 170, SW - 3, SH), M, c.shape))
    cv2.imwrite(str(out / '01.png'), c)
    # 02: Home night 10 km/h, then the zoomed «minutes left» box, moved down so it no longer covers the bubble
    c = cv2.imread(str(src / '02.jpg')); n = cv2.imread(str(sh / 'home-10kmh-night.png'))
    M, s, a, k = fit(c, n, (0, 170, SW, 1000), (0, 700, 1320, 2868)); check('02 schermo', s, a, k, 0.778, -3.0)
    Mc, s2, a2, k2 = fit(c, n, (700, 1600, SW, 2400), (720, 1500, 1290, 2240)); check('02 riquadro', s2, a2, k2, 1.600, 5.0)
    screen = box_mask((3, 170, SW - 3, SH), M, c.shape)
    # 1. the old box outside the screen: filled with the phone's edge and background 850 px further along the
    #    edge (its upper half from below, its lower half from above, both outside the old box)
    old = 1 - outside((900, 1640, 1340, 2150), Mc, c.shape)
    unit = M[:, 1] / np.hypot(*M[:, 1])
    H, W = c.shape[:2]; xs, ys = np.meshgrid(np.arange(W, dtype=np.float32), np.arange(H, dtype=np.float32))
    ys_box = ys[old > 0.5]; mid = (ys_box.min() + ys_box.max()) / 2
    sign = np.where(ys < mid, 1, -1).astype(np.float32) * 850
    sx = xs + sign * np.float32(unit[0])
    shifted = cv2.remap(c, sx, ys + sign * np.float32(unit[1]), cv2.INTER_LINEAR)
    straight = cv2.remap(c, xs, ys + sign, cv2.INTER_LINEAR)       # past the canvas edge: straight along y
    shifted = np.where((sx > W - 2)[..., None], straight, shifted)
    a = (old * (1 - screen))[..., None]
    c = (c * (1 - a) + shifted * a).round().astype(np.uint8)
    # 2. the screen
    c = paste(c, n, M, screen)
    # 3. the box, drawn again: red shadow, light border, content (the app's minutes, 15 px lower inside the box)
    ox, oy, PW, PH = 880, 1600, 480, 580
    patch = np.zeros((PH, PW, 3), np.uint8); alpha = np.zeros((PH, PW), np.float32)
    def rect(x0, y0, x1, y1, color):
        patch[y0 - oy:y1 - oy, x0 - ox:x1 - ox] = color; alpha[y0 - oy:y1 - oy, x0 - ox:x1 - ox] = 1
    rect(912 + 16, 1649 + 16, 1298 + 16, 2126 + 16, (48, 59, 255))
    rect(912, 1649, 1298, 2126, (255, 234, 226))
    d = 15
    patch[1657 - oy:2118 - oy, 920 - ox:1290 - ox] = n[1657 - d:2118 - d, 920:1290]
    T = np.float64([[1, 0, ox], [0, 1, oy], [0, 0, 1]])
    Mn = np.vstack([Mc, [0, 0, 1]]) @ T; Mn = Mn[:2].copy(); Mn[1, 2] += DOWN
    w = cv2.warpAffine(patch, Mn, (W, H), flags=cv2.INTER_CUBIC); al = cv2.warpAffine(alpha, Mn, (W, H), flags=cv2.INTER_LINEAR)[..., None]
    c = (c * (1 - al) + w * al).round().clip(0, 255).astype(np.uint8)
    cv2.imwrite(str(out / '02.png'), c)
    # 03: two crops of the road, 4 km/h and 10 km/h
    c0 = cv2.imread(str(src / '03.jpg')); c = c0.copy()
    na = cv2.imread(str(sh / 'home-4kmh-day.png')); nb = cv2.imread(str(sh / 'home-10kmh-day.png'))
    Ma, s, a, k = fit(c0, na, (0, 1500, SW, SH), (0, 780, 1320, 1820)); check('03 ritaglio 1', s, a, k, 0.893, -2.0)
    Mb, s, a, k = fit(c0, nb, (0, 1500, SW, SH), (0, 1820, 1320, 2868)); check('03 ritaglio 2', s, a, k, 0.893, 2.0)
    # the app's minutes now sit higher: the window on the screenshot moves up by D, so they keep their margin
    D = 70; crop = (0, 1715, SW, 2798)
    sh_ = lambda Mx: (np.vstack([Mx, [0, 0, 1]]) @ np.float64([[1, 0, 0], [0, 1, D], [0, 0, 1]]))[:2]
    c = paste(c, na, sh_(Ma), box_mask((0, 1715 - D, SW, 2798 - D), sh_(Ma), c.shape) * outside((-40, 1690, 1360, 2860), Mb, c.shape))
    c = paste(c, nb, sh_(Mb), box_mask((0, 1715 - D, SW, 2798 - D), sh_(Mb), c.shape))
    cv2.imwrite(str(out / '03.png'), c)
