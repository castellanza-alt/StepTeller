# Livelli dell'illustrazione della Home

Dagli originali (881 × 1786 px) si ricavano sfondo (`HomeArt*`) e scarpa + gamba (`HomeLeg*`) per la parallasse.
Serve un Mac (Vision) e Python con `pillow numpy scipy`.

```bash
swiftc -O subject.swift -o subject
./subject notte.png maschera-notte.png                # di giorno: prima scurire il cielo bianco, poi Vision
python3 moon.py notte.png notte-senza-raggi.png        # toglie i raggi intorno alla luna
python3 layers.py notte-senza-raggi.png maschera-notte.png sfondo.png gamba.png
```

`layers.py`: a riposo sfondo + gamba danno esattamente l'originale; la gamba ha 24 px di bordo ripetuto (`Manga.legPadding`).
