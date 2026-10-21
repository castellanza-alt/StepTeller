"""Splits the illustration into background (with the hole under shoe and leg filled in) and foreground
(shoe and leg cut out), for the Home parallax."""
import sys, numpy as np
from PIL import Image
from scipy import ndimage as nd
src, mask_path, out_bg, out_fg = sys.argv[1:5]
a = np.asarray(Image.open(src).convert('RGBA')).astype(np.float64)
m = np.asarray(Image.open(mask_path).convert('L')).astype(np.float64) / 255
rgb = a[..., :3]
# foreground: hard mask grown by 3 px (takes the outline of the leg), ~2 px soft edge
hard = nd.binary_dilation(m > 0.5, iterations=3)
alpha = np.clip(nd.gaussian_filter(hard.astype(np.float64), 1.0) * 1.15, 0, 1)
fg = a.copy()
fg[..., 3] = alpha * 255
# background: hole only where the foreground is solid (at rest the pair is identical to the original),
# filled from the edges inwards at growing scales
hole = alpha > 0.99
known = (~hole).astype(np.float64)
bg = rgb.copy()
filled = ~hole
for sigma in (4, 8, 16, 32, 64, 128):
    w = nd.gaussian_filter(known, sigma)
    sel = ~filled & (w > 0.08)
    for ch in range(3):
        f = nd.gaussian_filter(bg[..., ch] * known, sigma) / np.maximum(w, 1e-6)
        bg[..., ch][sel] = f[sel]
    filled |= sel
    known = filled.astype(np.float64)
# light grain so it is not a flat smudge
rng = np.random.default_rng(3)
bg[hole] += rng.normal(0, 2.0, (hole.sum(), 3))
out = a.copy(); out[..., :3] = bg; out[..., 3] = 255
Image.fromarray(np.clip(np.rint(out), 0, 255).astype(np.uint8)).save(out_bg, optimize=True)
# the foreground is saved cropped to its box (less memory), with the offset in the log
ys, xs = np.nonzero(fg[..., 3] > 0)
y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
# 24 px margin repeating the edge: when the foreground shifts the leg does not detach from the edge
PAD = 24
fg = np.pad(fg, ((PAD, PAD), (PAD, PAD), (0, 0)), mode='edge')
Image.fromarray(np.clip(np.rint(fg), 0, 255).astype(np.uint8)).save(out_fg, optimize=True)
print('riquadro primo piano', x0, y0, x1, y1)
