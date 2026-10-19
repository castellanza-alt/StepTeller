"""Divide l'illustrazione in sfondo (con il buco sotto scarpa e gamba riempito) e primo piano
(scarpa e gamba scontornate), per la parallasse della Home."""
import sys, numpy as np
from PIL import Image
from scipy import ndimage as nd
src, mask_path, out_bg, out_fg = sys.argv[1:5]
a = np.asarray(Image.open(src).convert('RGBA')).astype(np.float64)
m = np.asarray(Image.open(mask_path).convert('L')).astype(np.float64) / 255
rgb = a[..., :3]
# primo piano: maschera netta allargata di 3 px (prende il contorno della gamba), bordo sfumato di ~2 px
hard = nd.binary_dilation(m > 0.5, iterations=3)
alpha = np.clip(nd.gaussian_filter(hard.astype(np.float64), 1.0) * 1.15, 0, 1)
fg = a.copy()
fg[..., 3] = alpha * 255
# sfondo: buco solo dove il primo piano è pieno (a riposo l'insieme è identico all'originale),
# riempito dai bordi verso l'interno a scale crescenti
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
# leggera grana per non avere una macchia liscia
rng = np.random.default_rng(3)
bg[hole] += rng.normal(0, 2.0, (hole.sum(), 3))
out = a.copy(); out[..., :3] = bg; out[..., 3] = 255
Image.fromarray(np.clip(np.rint(out), 0, 255).astype(np.uint8)).save(out_bg, optimize=True)
# il primo piano si salva ritagliato al suo riquadro (meno memoria), con l'offset nel nome del log
ys, xs = np.nonzero(fg[..., 3] > 0)
y0, y1, x0, x1 = ys.min(), ys.max() + 1, xs.min(), xs.max() + 1
# margine di 24 px che ripete il bordo: spostando il primo piano la gamba non si stacca dal bordo
PAD = 24
fg = np.pad(fg, ((PAD, PAD), (PAD, PAD), (0, 0)), mode='edge')
Image.fromarray(np.clip(np.rint(fg), 0, 255).astype(np.uint8)).save(out_fg, optimize=True)
print('riquadro primo piano', x0, y0, x1, y1)
