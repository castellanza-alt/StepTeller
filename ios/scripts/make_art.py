#!/usr/bin/env python3
"""Illustrazioni dell'app (generate con Canva, fondo bianco) → imageset con fondo trasparente,
variante chiara e scura.

Uso: python3 scripts/make_art.py <cartella con oggi.png fiamma.png storico-alto.png storico-basso.png impronte.png>

- Chiaro: «colore ad alfa» sul bianco (il bianco diventa trasparente, il tratto resta com'è).
- Scuro: stessa trasparenza, luminosità invertita mantenendo tinta e saturazione: la matita nera
  diventa chiara, il rosso resta rosso.
"""
import colorsys
import json
import os
import sys

import numpy as np
from PIL import Image

ART = {
    "oggi.png": "ArtOggi",
    "fiamma.png": "ArtFiamma",
    "storico-alto.png": "ArtStoricoAlto",
    "storico-basso.png": "ArtStoricoBasso",
    "impronte.png": "ArtImpronte",
}
ASSETS = os.path.join(os.path.dirname(__file__), "..", "App", "Assets.xcassets")


def white_to_alpha(rgb: np.ndarray) -> tuple[np.ndarray, np.ndarray]:
    """rgb 0..1 → (colore senza il bianco, alfa)."""
    alpha = (1 - rgb).max(axis=2)
    alpha = np.where(alpha < 0.05, 0, alpha)                       # carta e rumore → trasparenti
    a = np.maximum(alpha, 1e-6)[..., None]
    color = np.clip(1 - (1 - rgb) / a, 0, 1)
    return color, alpha


def invert_lightness(color: np.ndarray) -> np.ndarray:
    hls = np.vectorize(colorsys.rgb_to_hls, otypes=[float, float, float])
    rgb = np.vectorize(colorsys.hls_to_rgb, otypes=[float, float, float])
    h, l, s = hls(color[..., 0], color[..., 1], color[..., 2])
    l2 = 0.12 + (1 - l) * 0.78                                     # mai bianco puro né nero puro
    # il rosso (saturo, luminosità media) resta com'è, solo un po' più acceso
    red = (s > 0.45) & (l > 0.25) & (l < 0.75)
    l2 = np.where(red, np.clip(l * 1.08, 0, 0.62), l2)
    r, g, b = rgb(h, l2, s)
    return np.stack([r, g, b], axis=2)


def save(color: np.ndarray, alpha: np.ndarray, path: str) -> None:
    out = np.dstack([color, alpha]) * 255
    Image.fromarray(out.round().astype(np.uint8), "RGBA").save(path, optimize=True)


def main(src: str) -> None:
    for name, asset in ART.items():
        rgb = np.asarray(Image.open(os.path.join(src, name)).convert("RGB"), dtype=np.float64) / 255
        color, alpha = white_to_alpha(rgb)
        folder = os.path.join(ASSETS, f"{asset}.imageset")
        os.makedirs(folder, exist_ok=True)
        save(color, alpha, os.path.join(folder, "light.png"))
        save(invert_lightness(color), alpha, os.path.join(folder, "dark.png"))
        contents = {
            "images": [
                {"filename": "light.png", "idiom": "universal"},
                {"filename": "dark.png", "idiom": "universal",
                 "appearances": [{"appearance": "luminosity", "value": "dark"}]},
            ],
            "info": {"author": "xcode", "version": 1},
        }
        with open(os.path.join(folder, "Contents.json"), "w") as f:
            json.dump(contents, f, indent=2)
        print(asset, rgb.shape[1], "×", rgb.shape[0])


if __name__ == "__main__":
    main(sys.argv[1])
