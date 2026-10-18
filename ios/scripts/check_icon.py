#!/usr/bin/env python3
"""Verifica l'icona dell'app (`App/AppIcon.icon`, Icon Composer): JSON valido, ogni immagine citata esiste,
i PNG sono 1024×1024. Xcode ne ricava le immagini per App Store e per iOS 17–18."""
import json
import struct
from pathlib import Path

icon = Path(__file__).resolve().parents[1] / 'App/AppIcon.icon'
doc = json.loads((icon / 'icon.json').read_text())
names = {spec['value'] for g in doc['groups'] for layer in g['layers'] for spec in layer['image-name-specializations']}
assert names, 'Nessun livello nell\'icona'
for name in sorted(names):
    path = icon / 'Assets' / name
    assert path.exists(), f'Manca {name}'
    if name.endswith('.png'):
        data = path.read_bytes()
        assert data[:8] == b'\x89PNG\r\n\x1a\n', f'{name}: non è un PNG'
        w, h = struct.unpack('!2I', data[16:24])
        assert (w, h) == (1024, 1024), f'{name}: {w}x{h}, serve 1024x1024'
    print('ok', name)
print('Icona valida:', icon.name)
