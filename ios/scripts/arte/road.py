"""Repaints the road under the sole in the background made by layers.py (same geometry by day and by night,
the two illustrations are the same drawing; colors are sampled from the image):
- flat asphalt instead of the dark blurred smudge, of the two grey blurred dashes and of the two white
  dashes above the series (x ≈ 97–458, y ≈ 1544–1699);
- flat asphalt also in the strip of the hole that the parallax uncovers under the sole (x ≈ 180–640);
- the speed lines that cross the area drawn again sharp, and three sharp dashes on the series, between
  the dash at x ≈ 490 and the one at x ≈ 44 (both kept).
Usage: python3 road.py sfondo.png gamba.png sfondo-corretto.png"""
import sys, numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as nd

SS = 8  # supersampling of the antialiased shapes
PAD = 24  # edge of the foreground (layers.py)


def coverage(polys, size):
    """Antialiased coverage (0…1) of the union of polygons given in px."""
    w, h = size
    im = Image.new('L', (w * SS, h * SS), 0)
    d = ImageDraw.Draw(im)
    for p in polys:
        d.polygon([(x * SS, y * SS) for x, y in p], fill=255)
    return np.asarray(im.resize((w, h), Image.BOX)).astype(np.float64) / 255


def taper(a, b):
    """Speed line from (x0, y0, width0) to (x1, y1, width1)."""
    (x0, y0, w0), (x1, y1, w1) = a, b
    dx, dy = x1 - x0, y1 - y0
    n = np.hypot(dx, dy); nx, ny = -dy / n, dx / n
    return [(x0 + nx * w0 / 2, y0 + ny * w0 / 2), (x1 + nx * w1 / 2, y1 + ny * w1 / 2),
            (x1 - nx * w1 / 2, y1 - ny * w1 / 2), (x0 - nx * w0 / 2, y0 - ny * w0 / 2)]


# Speed lines crossing the area, as in the drawing (the lower one starts after the new dash at x ≈ 165,
# instead of its blurred left end)
LINES = [((130, 1621.3, 2.9), (258, 1599.3, 0.0)),
         ((367, 1616.2, 0.6), (456, 1599.2, 2.1)),
         ((213, 1671.5, 1.8), (322, 1653.6, 0.0))]

# Series of dashes: centre line as a cubic Hermite in x between the dash at x ≈ 490 and the one at x ≈ 44
P0, S0 = (490.5, 1607.0), -0.22
P1, S1 = (44.0, 1712.0), -0.36
# centres of the new dashes: gaps 96, 98, 132 px after 75 px upstream
DASHES = [395, 297, 165]


def centre(x):
    h = P0[0] - P1[0]; t = (P0[0] - x) / h
    h00, h10, h01, h11 = 2*t**3 - 3*t**2 + 1, t**3 - 2*t**2 + t, -2*t**3 + 3*t**2, t**3 - t**2
    return h00 * P0[1] - h10 * h * S0 + h01 * P1[1] - h11 * h * S1


def dash(cx, i):
    """Parallelogram like the dash at x ≈ 490 (64 × 7 px): long sides along the road, ends slanted;
    a little longer and thicker as it gets closer."""
    length, thick = 66 + 3 * i, 8.0 + 0.7 * i
    s = centre(cx + 0.5) - centre(cx - 0.5)  # dy/dx
    xa, xb = cx - length / 2, cx + length / 2
    ya, yb = centre(cx) + (xa - cx) * s, centre(cx) + (xb - cx) * s
    e = 0.6 * thick
    return [(xa - e / 2, ya - thick / 2), (xb - e / 2, yb - thick / 2),
            (xb + e / 2, yb + thick / 2), (xa + e / 2, ya + thick / 2)]


def l3(x):
    """Lower speed line in the drawing (right of its blurred end)."""
    return 1675.8 - 0.170 * (x - 188)


def repaint(img, hole):
    H, W = img.shape[:2]
    # road area, from just below the sole to just above the lower line (around the new dash at x ≈ 165
    # down to below it), right edge before the dash at x ≈ 490
    area = [(140, 1603), (170, 1582), (205, 1572), (205, 1540), (458, 1540), (458, 1633), (430, 1637), (380, 1644),
            (330, 1651)] + [(x, l3(x) - 2.2) for x in (320, 280, 240, 215)] + \
           [(205, 1682), (125, 1698), (95, 1694), (95, 1676), (150, 1667)]
    mask = coverage([area], (W, H))
    xs = np.arange(W)[None, :].repeat(H, 0); ys = np.arange(H)[:, None].repeat(W, 1)
    # soft left end: on the faint speed lines (above) and on the rocks (around the blurred end of the line)
    left = np.where(ys < 1668, np.clip((xs - 138) / 26, 0, 1), np.clip((xs - 95) / 10, 0, 1))
    mask *= left
    mask *= np.clip((458 - xs) / 14, 0, 1)  # the right one fades into the asphalt with the speckles
    # strip under the sole uncovered by the parallax (hole of layers.py, invisible at rest)
    strip = hole & (xs >= 175) & (xs <= 640) & (ys >= 1440)
    strip = nd.gaussian_filter(strip.astype(np.float64), 4) * hole
    mask = np.maximum(nd.gaussian_filter(mask, 0.6), strip)

    lum = img.mean(2)
    ring = nd.binary_dilation(mask > 0.01, iterations=12) & ~nd.binary_dilation(mask > 0.01, iterations=3) & ~hole
    night = np.median(lum[ring]) < 128
    asphalt = np.median(img[ring & ((lum < 60) if night else (lum > 230))], 0)
    mark = np.median(img[1603:1608, 475:505].reshape(-1, 3), 0)

    res = img * (1 - mask[..., None]) + asphalt * mask[..., None]
    # around the soft left end, colours brought back on the asphalt–marks scale: no leftover of the pink
    # ring (day) or of the lilac specks (night) that were in the smudge
    zone = (xs >= 120) & (xs < 185) & (ys >= 1575) & (ys < 1700)
    axis = mark - asphalt
    t = ((res[zone] - asphalt) * axis).sum(1) / (axis * axis).sum()
    res[zone] = asphalt + np.clip(t, 0, 1)[:, None] * axis
    ink = coverage([taper(a, b) for a, b in LINES] + [dash(cx, i + 1) for i, cx in enumerate(DASHES)], (W, H))
    return res * (1 - ink[..., None]) + mark * ink[..., None], asphalt, mark


if __name__ == '__main__':
    src, leg, out = sys.argv[1:4]
    img = np.asarray(Image.open(src).convert('RGB')).astype(np.float64)
    alpha = np.asarray(Image.open(leg).convert('RGBA'))[PAD:-PAD, PAD:-PAD, 3]
    # only where the foreground is solid: at rest the pair stays identical outside the repainted road
    res, asphalt, mark = repaint(img, alpha == 255)
    Image.fromarray(np.clip(np.rint(res), 0, 255).astype(np.uint8)).save(out, optimize=True)
    print('asfalto', asphalt, 'segni', mark, 'trattini', [(cx, round(centre(cx), 1)) for cx in DASHES])
