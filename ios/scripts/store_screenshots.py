#!/usr/bin/env python3
"""Converts the store screenshots (PNG 1320 × 2868) to high-quality JPEG in store/screenshots/<language>/01…06.jpg.

Apple accepts JPEG for screenshots; JPEG keeps the repository light (PNG from Claude Design are ~3.5 MB each).
Quality 85 with full chroma (4:4:4), so the red labels and the thin text stay sharp; no alpha channel.
The output is the same for the same input, so a rerun leaves an empty diff.

Usage: python3 scripts/store_screenshots.py SOURCE [SOURCE…]
  SOURCE = a folder with one subfolder per language (it, en, es, fr, de, pt-BR, ja, ko, zh-Hans, zh-Hant)
           or `lang=folder` for a single language (e.g. it=localizzazione/design/claude-design-IT).
  In each folder the PNG files are taken in name order (01_…png … 06_…png).
Needs Pillow: pip install pillow
"""
import io
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "store" / "screenshots"
LANGUAGES = ["it", "en", "es", "fr", "de", "pt-BR", "ja", "ko", "zh-Hans", "zh-Hant"]
SIZE = (1320, 2868)  # iPhone 6.9" (App Store Connect: APP_IPHONE_67)
COUNT = 6


def sources(args):
    found = {}
    for arg in args:
        if "=" in arg:
            lang, folder = arg.split("=", 1)
            found[lang] = Path(folder)
        else:
            for lang in LANGUAGES:
                if (Path(arg) / lang).is_dir():
                    found[lang] = Path(arg) / lang
    return found


def convert(source: Path, target: Path):
    with Image.open(source) as image:
        if image.size != SIZE:
            raise SystemExit(f"{source}: {image.size[0]}×{image.size[1]}, attesi {SIZE[0]}×{SIZE[1]}")
        rgb = image.convert("RGB")
    buffer = io.BytesIO()
    rgb.save(buffer, "JPEG", quality=85, subsampling=0, optimize=True)
    target.write_bytes(buffer.getvalue())
    return len(buffer.getvalue())


def main():
    found = sources(sys.argv[1:])
    unknown = set(found) - set(LANGUAGES)
    if not found or unknown:
        raise SystemExit(__doc__ if not found else f"Lingue sconosciute: {sorted(unknown)}")
    total = 0
    for lang in LANGUAGES:
        if lang not in found:
            continue
        files = sorted(p for p in found[lang].iterdir() if p.suffix.lower() == ".png")
        if len(files) != COUNT:
            raise SystemExit(f"{found[lang]}: {len(files)} PNG, attesi {COUNT}")
        folder = OUT / lang
        folder.mkdir(parents=True, exist_ok=True)
        for old in folder.glob("*.jpg"):
            old.unlink()
        sizes = [convert(src, folder / f"{index:02d}.jpg") for index, src in enumerate(files, 1)]
        total += sum(sizes)
        print(f"{lang:8} {', '.join(p.name for p in files)} → {sum(sizes) // 1024} KB")
    missing = [lang for lang in LANGUAGES if not (OUT / lang).is_dir()]
    print(f"Totale {total // 1024} KB" + (f"; lingue ancora senza screenshot: {', '.join(missing)}" if missing else ""))


if __name__ == "__main__":
    main()
