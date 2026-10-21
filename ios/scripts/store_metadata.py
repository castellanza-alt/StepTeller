#!/usr/bin/env python3
"""Exports the App Store texts from the store sheet to store/metadata.json (read by `asc.py store-*`).

Source: localizzazione/NEAT_store_tradotto.xlsx, sheet «Store», rows store.name, store.subtitle, store.promo,
store.description, store.keywords (Italian + 9 languages). The sheet is only read. The JSON is regenerated, never
edited by hand: CI reads it so that it needs no spreadsheet library.

Keywords: Apple documents the field as «up to 100 bytes» (UTF-8). The Japanese, Korean and Chinese rows of the sheet
are 102–146 bytes, so KEYWORD_OVERRIDES holds shorter versions proposed to Will (whole words removed, none cut).

Usage: python3 scripts/store_metadata.py   (needs openpyxl: pip install openpyxl)
"""
import json
from pathlib import Path

import openpyxl

ROOT = Path(__file__).resolve().parent.parent
SHEET = ROOT / "localizzazione" / "NEAT_store_tradotto.xlsx"
OUT = ROOT / "store" / "metadata.json"

# sheet column → language code (same codes as the screenshot folders)
LANGUAGES = [
    ("Italiano", "it"),
    ("Inglese (EN)", "en"),
    ("Spagnolo (ES)", "es"),
    ("Francese (FR)", "fr"),
    ("Tedesco (DE)", "de"),
    ("Portoghese Brasile (PT-BR)", "pt-BR"),
    ("Giapponese (JA)", "ja"),
    ("Coreano (KO)", "ko"),
    ("Cinese semplificato (ZH-Hans)", "zh-Hans"),
    ("Cinese tradizionale (ZH-Hant)", "zh-Hant"),
]

# sheet ID → field name in the JSON
FIELDS = {
    "store.name": "name",
    "store.subtitle": "subtitle",
    "store.promo": "promotionalText",
    "store.description": "description",
    "store.keywords": "keywords",
}

# Shortened keywords (≤ 100 bytes), whole words dropped from the sheet row; pending Will's approval.
KEYWORD_OVERRIDES = {
    # dropped: カウンター, 徒歩, 時間, リマインダー
    "ja": "歩数計,ウォーキング,散歩,歩数,距離,記録,連続達成,ウィジェット,10000歩",
    # dropped: 측정
    "ko": "만보기,걷기,산책,걸음수,거리,시간,기록,위젯,알림,만보,연속달성,일일",
    # dropped: 计步 (already in 计步器), 步行时间, 步行距离, 步数记录
    "zh-Hans": "计步器,步数,走路,散步,步行,万步,每日步数,连续达标,小组件,提醒,10000步",
    # dropped: 計步 (already in 計步器), 步行時間, 步行距離, 步數紀錄
    "zh-Hant": "計步器,步數,走路,健走,散步,萬步,每日步數,連續達標,小工具,提醒,10000步",
}

LIMITS = {"name": 30, "subtitle": 30, "promotionalText": 170, "description": 4000}
KEYWORD_BYTES = 100


def main():
    sheet = openpyxl.load_workbook(SHEET, read_only=True, data_only=True)["Store"]
    rows = list(sheet.iter_rows(values_only=True))
    header = [str(c).strip() if c else "" for c in rows[0]]
    columns = {code: header.index(title) for title, code in LANGUAGES}
    texts = {code: {} for _, code in LANGUAGES}
    for row in rows[1:]:
        field = FIELDS.get(str(row[0] or "").strip())
        if not field:
            continue
        for code, index in columns.items():
            value = str(row[index] or "").strip()
            if not value:
                raise SystemExit(f"Cella vuota: {row[0]} / {code}")
            texts[code][field] = value
    for code, keywords in KEYWORD_OVERRIDES.items():
        texts[code]["keywords"] = keywords
    problems = []
    for code, fields in texts.items():
        missing = set(FIELDS.values()) - set(fields)
        if missing:
            problems.append(f"{code}: mancano {sorted(missing)}")
        for field, limit in LIMITS.items():
            if len(fields.get(field, "")) > limit:
                problems.append(f"{code} {field}: {len(fields[field])} caratteri > {limit}")
        size = len(fields.get("keywords", "").encode())
        if size > KEYWORD_BYTES:
            problems.append(f"{code} keywords: {size} byte > {KEYWORD_BYTES}")
    if problems:
        raise SystemExit("\n".join(problems))
    OUT.parent.mkdir(exist_ok=True)
    data = {"_source": "Generato da scripts/store_metadata.py dal foglio «Store»: non modificare a mano.",
            "languages": texts}
    OUT.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"{OUT.relative_to(ROOT)}: {len(texts)} lingue")
    for code, fields in texts.items():
        print(f"  {code:8} nome {len(fields['name']):2}  sottotitolo {len(fields['subtitle']):2}  "
              f"promo {len(fields['promotionalText']):3}  descrizione {len(fields['description']):4}  "
              f"parole chiave {len(fields['keywords']):3} car. / {len(fields['keywords'].encode()):3} byte")


if __name__ == "__main__":
    main()
