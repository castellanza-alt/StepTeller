#!/usr/bin/env python3
"""Verifica l'icona dell'app: PNG 1024×1024, RGB (senza canale alfa), come richiede App Store Connect."""
import struct
import sys
from pathlib import Path

path = Path(__file__).resolve().parents[1] / 'App/Assets.xcassets/AppIcon.appiconset/icon-1024.png'
data = path.read_bytes()
assert data[:8] == b'\x89PNG\r\n\x1a\n', 'Non è un PNG'
width, height, depth, color = struct.unpack('!2I2B', data[16:26])
assert (width, height) == (1024, 1024), f'Dimensione {width}x{height}: serve 1024x1024'
assert color == 2, f'Tipo colore {color}: serve RGB senza trasparenza (2)'
assert depth == 8, f'Profondità {depth}: serve 8 bit'
print('Icona valida:', path.name)
