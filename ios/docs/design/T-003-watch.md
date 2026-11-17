# T-003 Apple Watch: schermata e complicazioni

**Designer, 17/11/2026.** Base: codice di `origin/ia/1.2-watch` (601c235): `Watch/WatchHomeView.swift`,
`Shared/StepsWidgetView.swift` (`LockCircular`, `LockRectangular`, `WidgetProgressBar`), `LiveActivity/StepsWidget.swift`
(`WatchCorner`, inline). Anteprima ferma, prima e dopo: https://claude.ai/artifact/ANTG7eMeBxCghsUBB678ae (sorgente: `T-003-watch-anteprima.html`)

Regole generali
- Solo token esistenti di `App/Design/MangaTokens.swift`. Nessun token nuovo.
- Il Watch usa **sempre la palette notte** (il quadrante è scuro, niente giorno/notte):
  `paper` **#0E1430**, `ink` **#E2EAFF**, `red` **#FF3B30**. Valori giorno (non usati sul Watch, per riferimento):
  `paper` #FFFFFF, `ink` #141414, `red` #E5231B.
- Font: solo Anton (`AntonText`, `Font.anton`). Taglie in pt **sul riferimento 41 mm** e moltiplicate per
  `k = larghezza / 176`. `tracking` in em come in `AntonText`.
- `manga(rotate:skew:anchor:)` è la trasformazione esistente; gli angoli sono in gradi.
- Testi: chiavi già presenti in `Shared/Widget.xcstrings` (nessuna traduzione nuova). Il testo italiano è tra «».

## 1. Schermata principale (`WatchHomeView`)

### 1.1 Telaio e misure per cassa
La vista ignora l'area sicura (`.ignoresSafeArea()`) e disegna su tutto lo schermo; l'ora di sistema resta in alto a
destra. Due gruppi: **gruppo alto** fissato dall'alto, **gruppo basso** fissato dal basso; lo spazio che avanza va
tra i due. (Oggi: `VStack` con due `Spacer` dentro l'area sicura, quindi le posizioni cambiano con l'altezza
dell'area sicura e il blocco passi «galleggia».)

| Cassa | Schermo (pt) | k | Fine gruppo alto | Inizio barra | Spazio libero |
|---|---|---|---|---|---|
| 41 mm (S7–S9) | 176 × 215 | 1,000 | y 117 | y 149 | 32 |
| 45 mm (S7–S9) | 198 × 242 | 1,125 | y 132 | y 168 | 36 |
| 49 mm (Ultra) | 205 × 251 | 1,165 | y 136 | y 174 | 38 |
| 42 mm (S10+) | 187 × 223 | 1,063 | y 124 | y 153 | 29 |
| 46 mm (S10+) | 208 × 248 | 1,182 | y 138 | y 170 | 32 |

Margine sinistro `16k` per i contatori, `12k` per tutto il resto; margine destro `12k`. Gli angoli dello schermo
sono arrotondati (raggio ≈ 34 pt sul 41 mm): niente testo sopra `y 10k` né sotto `H − 22k` (la riga minuti, inclinata e obliqua, sporge di ≈ 2 pt a sinistra in basso).
Se lo spazio libero scendesse sotto `12k` (non succede su nessuna cassa in tabella) il numero dei passi si riduce
fino a 0,6 (`minScale` già presente).

### 1.2 Gruppo alto (dall'alto, valori a 41 mm, tutto × k)

| Elemento | Posizione | Dettagli | Rispetto a oggi |
|---|---|---|---|
| Contatori serie e Jolly | x 16, y 12 | `FlameIcon(.streak)` 12 × 15 (`red` #FF3B30) + numero Anton 15 `ink`, spazio 3; poi 10 di spazio; `FlameIcon(.jolly)` 12 × 15 (`ink` #E2EAFF con anima `red`) + numero Anton 15. `manga(rotate: -3, skew: -8, anchor: .leading)` | stesso disegno; x da 10 a 16 e y fissa (oggi dipende dall'area sicura). Larghezza massima 90: non tocca l'ora |
| Etichetta | x 12, y 40, alta 11 | «PASSI DI OGGI» (`w.stepsToday`), Anton 11, tracking 0,06, `ink` | **nuova**: come la Home dell'iPhone e il widget medio |
| Passi | sotto l'etichetta, `padding.top` 2 + `TitleFont.gap(11)` | Anton 54, lineHeight 0,92 (alto 49,7), tracking −0,035, `ink`; ombra dura: stessa scritta in `red` spostata **+3, +3**. `minScale` 0,6 sulla larghezza 152. Testo «3.465» (`LocalFormat.integer`) | uguale |
| Obiettivo | sotto i passi, `padding.top` 2 | «SU 10.000» (`w.of`), Anton 12, tracking 0,06, `ink`. Senza dati: lo stesso «SU 10.000» (l'obiettivo arriva dall'iPhone) | oggi senza dati mostra «PASSI»: va mostrato l'obiettivo. Serve l'obiettivo in `WidgetSnapshot` anche con `plan == nil` (campo `goal: Int`) |
| Trasformazione del blocco | etichetta + passi + obiettivo insieme | `manga(rotate: -6, skew: -10, anchor: .bottomLeading)` | oggi l'etichetta non c'è; angoli uguali |

### 1.3 Gruppo basso (dal basso, valori a 41 mm, tutto × k)

| Elemento | Posizione | Dettagli | Rispetto a oggi |
|---|---|---|---|
| Riga minuti | fondo della riga a `H − 24`, x 12, larghezza 152 | `HStack(alignment: .lastTextBaseline, spacing: 4)`: «MANCANO» (`w.left`) Anton 12 tracking 0,04 `ink` · **«37»** Anton 24 tracking −0,02 `red` · «MIN · 2,9 KM» (`w.minKm`, in miglia `w.minMi`) Anton 12 tracking 0,04 `ink`. `manga(rotate: -3, skew: -9, anchor: .leading)`, `minScale` 0,7 | oggi una riga sola Anton 12 «ANCORA 37 MIN · 2,9 KM» tutta `ink`: i minuti diventano il secondo numero grande, rosso, come nel widget medio |
| Barra | 10 sopra la riga minuti, x 14, 148 × 8 | `WidgetProgressBar`: fondo `paper` #0E1430, riempimento `red` #FF3B30, bordo 1,5 `ink` #E2EAFF su fondo e riempimento. `manga(rotate: -1.5, skew: -20)` | oggi larghezza `176 − 26 = 150`, senza rotazione: −1,5° come nel widget medio |

### 1.4 Stati
| Stato | Passi | Obiettivo | Barra | Riga in basso |
|---|---|---|---|---|
| In corso (`plan`, non `isDone`) | «3.465» | «SU 10.000» | avanzamento | «MANCANO **37** MIN · 2,9 KM» |
| **Obiettivo raggiunto** (`isDone`) | «10.729» | «SU 10.000» | piena | «OBIETTIVO» (`w.goal`) Anton 12 `ink` + **«FATTO!»** (`w.done`) Anton 24 `red`, stessa riga e stessa trasformazione della riga minuti |
| Niente dati (`plan == nil`) | «—» | «SU 10.000» | vuota | targhetta «NIENTE DATI DA SALUTE» (`w.watch.nodata`): Anton 11 tracking 0,06, testo `paper` su fondo `ink`, padding 5 orizzontale e 2 verticale, `manga(rotate: -3, skew: -9)` (come `TagText` della Home) |

Oggi lo stato raggiunto è una riga Anton 12 «OBIETTIVO RAGGIUNTO» in rosso: troppo piccola per il momento più
importante della giornata. La chiave `w.lock.goalDone` resta per la complicazione rettangolare.

### 1.5 Movimento
| Cosa | Curva | Quando |
|---|---|---|
| Numero dei passi e dei minuti | `.contentTransition(.numericText())` con `.spring(duration: 0.5, bounce: 0.15)` (= `.snappy`, come la Home) | nuovo valore da Salute |
| Riempimento della barra | `.easeOut(duration: 0.4)` sulla larghezza | nuovo valore |
| Passaggio a «OBIETTIVO FATTO!» | dissolvenza `.easeInOut(duration: 0.25)` (come la Home); poi «FATTO!» da scala 0,6 a 1 con `.spring(duration: 0.5, bounce: 0.45)` e ritardo 0,05 s (come `GoalCelebration`) | una volta, quando `isDone` passa da falso a vero con l'app aperta |
| Riduci movimento | solo dissolvenza 0,25 s, niente scala e niente molla | `accessibilityReduceMotion` |

Oggi non c'è nessuna animazione. Nessun tocco aptico (fuori da questa specifica: decide il Director).

### 1.6 VoiceOver
Invariato: frase intera `WidgetText.summary` o «Nessun dato da Salute. Controlla i permessi di NEAT nell'app Salute
del telefono.» (`w.watch.nodata.vo`).

## 2. Complicazioni

Sul Watch le complicazioni si vedono in due modi (`@Environment(\.widgetRenderingMode)`):
- **`.fullColor`** (quadranti a colori): si usano i colori notte, fondo trasparente sul nero del quadrante.
- **`.accented` / `.vibrant`** (quadranti tinti): bianco e trasparenze come oggi; la parte di avanzamento è
  `.widgetAccentable()`.

Oggi tutto è bianco in ogni modo: sui quadranti a colori NEAT è l'unica complicazione senza il suo rosso.
Le modifiche valgono solo sotto `#if os(watchOS)`: il blocco schermo dell'iPhone (1.1) non cambia.

Misure delle famiglie (pt, dalle linee guida Apple, **da confermare sul Simulatore**):

| Famiglia | 41 mm | 45 mm | 49 mm |
|---|---|---|---|
| Tondo (`accessoryCircular`) | 44,5 × 44,5 | 50 × 50 | 50 × 50 |
| Rettangolo (`accessoryRectangular`) | 165 × 72 | 185 × 80 | 191 × 81 |
| Angolo (`accessoryCorner`) | contenuto ≈ 32 × 32 | ≈ 36 × 36 | ≈ 36 × 36 |
| Riga (`accessoryInline`) | solo testo + simbolo | | |

Le misure qui sotto sono a 41 mm e scalano con `k = lato / 44,5` (tondo) e `k = larghezza / 165` (rettangolo).

### 2.1 Tondo
| | Oggi | Dopo |
|---|---|---|
| Anello | rientro 3, spessore 6, traccia bianco 30 %, avanzamento bianco | rientro 2, spessore **4**, tappo tondo, inizio a ore 12. `.fullColor`: traccia `ink` #E2EAFF al 25 %, avanzamento `red` #FF3B30. Tinto: traccia bianco 30 %, avanzamento bianco `.widgetAccentable()` |
| Numero | Anton 19, «3.465» (compatto solo da 10.000), si riduce fino a 0,6 (11 pt) | Anton **17**, tracking −0,02, **sempre compatto da 1.000**: «3,5K», «10,4K»; sotto 1.000 «850». Colore `.fullColor`: `ink`; raggiunto: `red`. Diametro libero dentro l'anello: 32,5 |
| Etichetta | «PASSI» Anton 9 | **tolta** (a 9 pt non si legge; il nome è nella galleria) |
| Trasformazione | `manga(skew: -10)` | uguale |
| Senza dati | «—» | «—» Anton 17, anello solo traccia |

### 2.2 Rettangolo
Tre righe allineate a sinistra, `spacing` 3, larghezza piena.

| Riga | Oggi | Dopo |
|---|---|---|
| 1 | fiamma 10 × 12 + «14 giorni» Anton 12 | fiamma serie 10 × 12 + «14» Anton 12 · 8 di spazio · fiamma Jolly 10 × 12 + «2» Anton 12 (come i contatori dell'app, senza la parola «giorni»). `.fullColor`: fiamme come `FlameIcon` (serie `red`, Jolly `ink` con anima `red`), numeri `ink`. Tinto: tutto bianco, fiamme `.widgetAccentable()` |
| 2 | passi Anton 30, `skew -10` | passi Anton **30** lineHeight 0,95 tracking −0,03 + «SU 10.000» Anton 11 tracking 0,06, allineati alla linea di base, 5 di spazio; insieme `manga(skew: -10, anchor: .bottomLeading)`. Passi `ink` (`.fullColor`) / bianco (tinto) |
| 3 | «ANCORA 37 MIN · 2,9 KM» Anton 12, bianco all'85 % | stesso testo e taglia; `.fullColor`: il numero dei minuti in `red`, il resto `ink`; tinto: bianco all'85 % come oggi. Raggiunto: «OBIETTIVO RAGGIUNTO» (`w.lock.goalDone`) in `red` (`.fullColor`) / bianco (tinto). Senza dati: «APRI L'APP» (`w.openApp`) |

Altezza a 41 mm: 12 + 3 + 28,5 + 3 + 12 = 58,5 su 72.

### 2.3 Riga
Invariata: simbolo `flame.fill` + «3.465 passi» (`w.inline`); senza dati «Passi —» (`w.inline.none`). È testo di
sistema: il quadrante decide font e colore.

### 2.4 Angolo
| | Oggi | Dopo |
|---|---|---|
| Centro | passi compatti Anton 20, bianco, `minScale` 0,6 | passi compatti (regola del tondo) Anton **18**, tracking −0,02, `manga(skew: -10)`; `.fullColor` `ink`, raggiunto `red` |
| Arco | `Gauge` senza colore | stesso `Gauge` in `.widgetLabel`, `.tint(red #FF3B30)` in `.fullColor`; tinto `.widgetAccentable()` |

## 3. Cosa resta aperto
- Misure delle complicazioni da verificare sul Simulatore watchOS (non avviato in questo compito).
- Campo `goal` in `WidgetSnapshot` anche senza dati (§1.2): piccola modifica al modello, a carico del Developer.
- Tocco aptico all'obiettivo raggiunto: proposta possibile, non specificata.
