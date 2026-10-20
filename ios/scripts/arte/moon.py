"""Removes the rays around the moon in the night illustration: the sky in the ray area is
rebuilt smooth from the clean pixels nearby; moon, stars, mountains and distant trails stay."""
import sys, numpy as np
from PIL import Image
from scipy import ndimage as nd
src, out = sys.argv[1], sys.argv[2]
a = np.asarray(Image.open(src).convert('RGBA')).astype(np.float64)
rgb = a[..., :3]; H, W = rgb.shape[:2]
lum = 0.299 * rgb[..., 0] + 0.587 * rgb[..., 1] + 0.114 * rgb[..., 2]
yy, xx = np.mgrid[0:H, 0:W]
mx, my, mr = 100, 700, 50
rad = np.hypot(xx - mx, yy - my)
moon = rad <= mr + 1.5
hx = [0, 30, 100, 165, 200, 222, 228, 240, 252, 262, 270, 282, 287, 295, 300, 360, 440]
hy = [722, 722, 726, 721, 733, 733, 716, 716, 700, 700, 694, 694, 714, 736, 736, 742, 742]
horizon = np.interp(xx, hx, hy)
above = yy < horizon - 2
R0, R1 = 285, 305                      # radius of the area and edge fade
zone = above & ~moon & (rad < R1)
bg = nd.median_filter(lum, size=17)
cand = zone & (lum - bg > 5)
r, g, b = rgb[..., 0], rgb[..., 1], rgb[..., 2]
red = (r > b + 30) & (r > g + 30)
# stars: compact, round components (not aligned with a ray)
strong = zone & (lum - bg > 9) & ~red
lab, n = nd.label(strong, structure=np.ones((3, 3)))
stars = np.zeros_like(strong)
for i, sl in enumerate(nd.find_objects(lab), 1):
    h = sl[0].stop - sl[0].start; w = sl[1].stop - sl[1].start
    comp = lab[sl] == i
    if comp.sum() >= 3 and max(h, w) <= 26 and max(h, w) / min(h, w) < 1.5 and comp.sum() / (h * w) > 0.25 \
            and (b[sl][comp] - r[sl][comp]).mean() < 40 and lum[sl][comp].max() > 115:
        stars[sl] |= comp
stars = nd.binary_dilation(stars, iterations=2) & zone
protect = stars | red
dirty = nd.binary_dilation(cand, iterations=3) | moon | ~above
clean = (~dirty).astype(np.float64)
smooth = np.empty_like(rgb)
w = nd.gaussian_filter(clean, 9)
for ch in range(3):
    smooth[..., ch] = nd.gaussian_filter(rgb[..., ch] * clean, 9) / np.maximum(w, 1e-6)
ok = w > 0.02
alpha = np.clip((R1 - rad) / (R1 - R0), 0, 1) * zone * ok * ~protect
alpha = nd.gaussian_filter(alpha, 1.0) * zone * ~protect
res = a.copy()
res[..., :3] = rgb * (1 - alpha[..., None]) + smooth * alpha[..., None]
Image.fromarray(np.clip(np.rint(res), 0, 255).astype(np.uint8)).save(out, optimize=True)
print('stelle tenute', nd.label(stars)[1])
