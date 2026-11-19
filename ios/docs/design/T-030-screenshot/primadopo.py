import sys
from PIL import Image, ImageDraw, ImageFont
old, new, out = sys.argv[1], sys.argv[2], sys.argv[3]
w, h, g = 600, 1304, 24
font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial Bold.ttf', 44)
c = Image.new('RGB', (3 * w + 2 * g + 80, 2 * h + g + 140), '#F3F1EC'); d = ImageDraw.Draw(c)
for r, (lab, folder) in enumerate([('PRIMA (oggi sullo store)', old), ('DOPO (1.3)', new)]):
    y = 20 + r * (h + 70 + g)
    d.text((40, y), lab, fill='#E5231B' if r else '#141414', font=font)
    for i in range(3):
        ext = 'jpg' if r == 0 else 'png'
        im = Image.open(f'{folder}/0{i+1}.{ext}').convert('RGB').resize((w, h), Image.LANCZOS)
        c.paste(im, (40 + i * (w + g), y + 60))
c.save(out, quality=88)
