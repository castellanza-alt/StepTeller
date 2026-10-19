#!/usr/bin/env python3
"""Rigenera i font dei titoli per giapponese, coreano e cinese, ridotti ai soli caratteri che l'app mostra.

Anton (titoli) ha solo l'alfabeto latino: in JA/KO/ZH i caratteri che mancano li disegna un font OFL spesso,
ridotto al sottoinsieme usato. I caratteri da coprire sono:
  - tutti i testi della lingua nel foglio localizzazione/NEAT_testi_tradotti.xlsx (foglio «Testi»);
  - i testi che iOS genera nell'app (date di Impostazioni e record, titoli dei periodi, nomi e iniziali di mesi e
    giorni, numeri), prodotti con gli stessi formattatori dell'app da scripts/font_asia/stringhe.swift.
Restano esclusi quelli che Anton ha già (lettere latine, cifre, punteggiatura come → ≈ —).

I font interi si scaricano da github.com/google/fonts a un commit fisso e si controllano con SHA-256 (cache in
build/font_asia/). Uscita in App/Fonts/: un .ttf per lingua e la licenza OFL accanto. Alla fine verifica che ogni
carattere sia nel font ridotto (o in Anton) e si ferma con errore se ne manca uno.

Da rilanciare ogni volta che cambiano le traduzioni del foglio:
  python3 scripts/font_asia.py        (serve: pip install openpyxl fonttools; Xcode per swiftc)
"""
import hashlib
import json
import os
import re
import subprocess
import sys
import tempfile
import urllib.request
from pathlib import Path

from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

sys.path.insert(0, str(Path(__file__).resolve().parent))
import cataloghi  # noqa: E402  (stesso foglio, stesse colonne)

ROOT = Path(__file__).resolve().parent.parent
FONTS = ROOT / "App" / "Fonts"
CACHE = ROOT / "build" / "font_asia"
ANTON = FONTS / "Anton-Regular.ttf"
GOOGLE_FONTS = "https://raw.githubusercontent.com/google/fonts/47d54ca1ebb14fd864695f1d39dc734f39017c33/ofl/"

# lingua → font. `file`: nome in App/Fonts; `wght`: istanza del font variabile (900 = Black).
TARGETS = {
    "ja": dict(file="DelaGothicOne-NEAT.ttf", src="delagothicone/DelaGothicOne-Regular.ttf", wght=None,
               sha="4ff87a0965f1b0505e5a2c58424bc6ad3cff27e56a82f21c2fc9d6b0e3857ee2", locale="ja_JP", license="DelaGothicOne-OFL.txt"),
    "ko": dict(file="BlackHanSans-NEAT.ttf", src="blackhansans/BlackHanSans-Regular.ttf", wght=None,
               sha="31960809284026681774a8e52dc19ebcad26cf69b0ad9d560f288296fbb52739", locale="ko_KR", license="BlackHanSans-OFL.txt"),
    "zh-Hans": dict(file="NotoSansSC-Black-NEAT.ttf", src="notosanssc/NotoSansSC%5Bwght%5D.ttf", wght=900,
                    sha="a3041811a78c361b1de50f953c805e0244951c21c5bd412f7232ef0d899af0da", locale="zh_CN", license="NotoSansSC-OFL.txt"),
    "zh-Hant": dict(file="NotoSansTC-Black-NEAT.ttf", src="notosanstc/NotoSansTC%5Bwght%5D.ttf", wght=900,
                    sha="864727d210d54f2537bbe23b3a839436c3992af72de9322af5270897246bd44f", locale="zh_TW", license="NotoSansTC-OFL.txt"),
}


def fetch(rel, sha):
    """Scarica (una volta) un file di google/fonts e ne controlla lo SHA-256."""
    dest = CACHE / rel.replace("%5B", "[").replace("%5D", "]")
    if not dest.exists():
        dest.parent.mkdir(parents=True, exist_ok=True)
        print(f"scarico {rel}")
        with urllib.request.urlopen(GOOGLE_FONTS + rel) as r:
            dest.write_bytes(r.read())
    digest = hashlib.sha256(dest.read_bytes()).hexdigest()
    if sha and digest != sha:
        sys.exit(f"{rel}: SHA-256 {digest}, atteso {sha}")
    return dest


def system_strings():
    """Testi generati da iOS per ogni lingua, con i formattatori dell'app (compilati per macOS)."""
    tmp = Path(tempfile.mkdtemp())
    sources = sorted((ROOT / "Sources" / "StepTellerCore").glob("*.swift")) + [
        ROOT / "Shared" / "Localization.swift", ROOT / "App" / "HistoryLabels+System.swift"]
    for s in sources:   # un solo modulo: niente `import StepTellerCore`
        (tmp / s.name).write_text(re.sub(r"^import StepTellerCore\n", "", s.read_text(), flags=re.M))
    (tmp / "main.swift").write_text((ROOT / "scripts" / "font_asia" / "stringhe.swift").read_text())
    exe = tmp / "stringhe"
    subprocess.run(["xcrun", "swiftc", "-O", "-swift-version", "5", "-o", str(exe)] + [str(p) for p in tmp.glob("*.swift")],
                   check=True)
    out = {}
    for lang, t in TARGETS.items():
        r = subprocess.run([str(exe), "-AppleLanguages", f"({lang})", "-AppleLocale", t["locale"]],
                           check=True, capture_output=True, text=True)
        out[lang] = r.stdout
    return out


def main():
    rows = cataloghi.load_rows()
    columns = {code: col for col, code in cataloghi.LANGUAGES}
    generated = system_strings()
    anton = TTFont(ANTON).getBestCmap()
    report = {}
    for lang, t in TARGETS.items():
        sheet = "".join(row[columns[lang]] for row in rows.values())
        text = sheet + generated[lang]
        need = sorted({c for c in text if not c.isspace() and ord(c) >= 0x20 and ord(c) not in anton})
        src = fetch(t["src"], t["sha"])
        font = TTFont(src)
        if t["wght"]:
            font = instancer.instantiateVariableFont(font, {"wght": t["wght"]}, updateFontNames=True)
        missing = [c for c in need if ord(c) not in font.getBestCmap()]
        if missing:
            sys.exit(f"{lang}: il font {t['src']} non ha {''.join(missing)}")
        opts = subset.Options()
        opts.layout_features = ["*"]
        opts.name_IDs = ["*"]
        opts.name_languages = ["*"]
        opts.notdef_outline = True
        sub = subset.Subsetter(opts)
        sub.populate(text="".join(need))
        sub.subset(font)
        out = FONTS / t["file"]
        font.recalcTimestamp = False      # stessa data del font originale: file identico a ogni rigenerazione
        font.save(out)
        lic = fetch(t["src"].split("/")[0] + "/OFL.txt", "")
        (FONTS / t["license"]).write_bytes(lic.read_bytes())
        # verifica sul file salvato
        cmap = TTFont(out).getBestCmap()
        lost = [c for c in need if ord(c) not in cmap]
        if lost:
            sys.exit(f"{lang}: dopo la riduzione mancano {''.join(lost)}")
        ps = TTFont(out)["name"].getDebugName(6)
        report[lang] = dict(file=t["file"], postscript=ps, chars=len(need), kb=round(os.path.getsize(out) / 1024),
                            from_ios="".join(sorted({c for c in generated[lang] if ord(c) not in anton and not c.isspace()} - set(sheet))))
        print(f"{lang}: {t['file']} ({ps}) — {len(need)} caratteri, {report[lang]['kb']} KB, tutti coperti")
        if report[lang]["from_ios"]:
            print(f"   solo nei testi di iOS: {report[lang]['from_ios']}")
    (CACHE / "rapporto.json").write_text(json.dumps(report, ensure_ascii=False, indent=1))


if __name__ == "__main__":
    main()
