# Livelli dell'illustrazione della Home

Dagli originali (881 × 1786 px) si ricavano sfondo (`HomeArt*`) e scarpa + gamba (`HomeLeg*`) per la parallasse.
Serve un Mac (Vision) e Python con `pillow numpy scipy`.

```bash
swiftc -O subject.swift -o subject
./subject notte.png maschera-notte.png                # di giorno: prima scurire il cielo bianco, poi Vision
python3 moon.py notte.png notte-senza-raggi.png        # toglie i raggi intorno alla luna
python3 layers.py notte-senza-raggi.png maschera-notte.png sfondo.png gamba.png
python3 road.py sfondo.png gamba.png sfondo.png        # strada sotto la suola ridipinta
```

`layers.py`: a riposo sfondo + gamba danno esattamente l'originale; la gamba ha 24 px di bordo ripetuto (`Manga.legPadding`).

`road.py` (ottobre 2026, dopo `layers.py`, stessa geometria di giorno e di notte): nel disegno, sotto la suola, la strada
aveva un'ombra scura sfocata, due trattini grigi sfocati (quelli veri della serie, coperti) e due trattini bianchi
fuori serie, circa 20 px più in alto; con la parallasse si vedevano. Lo script ridipinge la zona (x ≈ 97–458,
y ≈ 1544–1699) con asfalto piatto, ridisegna nitide le tre linee di velocità che la attraversano e mette tre trattini
nitidi sulla serie, fra quello a x ≈ 490 e quello a x ≈ 44 (intervalli crescenti 96, 98, 132 px). Riempie di asfalto
anche la striscia del buco che la parallasse scopre sotto la suola. Colori presi dall'immagine (asfalto intorno,
interno del trattino a x ≈ 490). A riposo sfondo + gamba cambiano solo in quel riquadro; la gamba non cambia.
