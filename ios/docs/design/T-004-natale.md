# T-004 Tema stagionale di Natale

**Designer, 17/11/2026.** Regole: D-036, D-037. Anteprima ferma: https://claude.ai/artifact/3LNgsKGVLzj6iGs2bF2QB4 (sorgente
`T-004-natale/anteprima.html`). Icona pronta in `T-004-natale/AppIconNatale.icon/`.

Regole generali
- Misure in pt sul telaio 390 × 844 (`Manga.frameWidth/frameHeight`), come il resto dell'app.
- Colori solo da token. Quelli di `MangaPalette` (`paper`, `ink`, `red`) **restano uguali**: il rosso è già il colore
  del Natale e sta dentro le illustrazioni. Il tema aggiunge 3 token stagionali (§2) e una forma (il cappello, §3).
- Le decorazioni sono tutte `accessibilityHidden(true)` e non ricevono tocchi (`allowsHitTesting(false)`).
- Testi nuovi: **2** (§7). Nessun altro testo cambia.

## 1. Periodo
**Dal 1° dicembre alle 00:00 al 6 gennaio alle 23:59**, ora locale del telefono (calendario `Calendar.current`).
Confermato: l'Epifania chiude le feste in Italia; prima del 1° dicembre il tema arriverebbe troppo presto.
Fuori periodo, o con l'interruttore spento (§5), l'app è identica alla 1.1.

## 2. Token stagionali (nuovi, in `MangaTokens.swift`)
Struttura proposta: `struct SeasonPalette { let snow, gold, pine: Color }` con `static let christmasDay` e
`christmasNight`, scelta come `MangaPalette.of(_:)` dal tema giorno/notte già risolto.

| Token | Giorno | Notte | Uso |
|---|---|---|---|
| `snow` | **#AFC0DC** | **#FFFFFF** | fiocchi di neve (su carta bianca serve un grigio-azzurro, di notte bianco) |
| `gold` | **#E09A12** | **#FFC94A** | lampadine gialle, scintille |
| `pine` | **#1D7A4C** | **#46C487** | lampadine verdi, scintille |

Colori esistenti usati dal tema: `red` (giorno #E5231B, notte #FF3B30), `ink` (giorno #141414, notte #E2EAFF),
`MangaPalette.iconWhite` #FFFFFF (bordo e pon-pon del cappello, uguale nei due temi).

## 3. Il cappello (forma nuova `MangaPaths.santaHat`, viewBox 40 × 33)
Stesso disegno del cappello dell'icona, ridotto. Tre pezzi:
- **cono**, riempito `red`, contorno `ink` 1,5:
  `M37.1 25.8 C31.1 13.2 22.1 1.8 11.9 0.6 C7.1 0.0 4.1 3.6 4.7 8.7 C8.3 6.3 11.3 9.0 8.3 25.8 Z`
- **bordo**: rettangolo x 4,1, y 23,7, 36 × 9, raggio 4,5; riempito `iconWhite`, contorno `ink` 1,5
- **pon-pon**: cerchio centro (4,8; 8,9), raggio 4,8; riempito `iconWhite`, contorno `ink` 1,5
- Ordine: cono, pon-pon, bordo (il bordo copre la base del cono). Punto di aggancio = **centro del bordo (22,1; 28,2)**:
  tutte le posizioni sotto indicano dove va quel punto. Lo spessore del contorno resta 1,5 a ogni scala.

| Dove | Larghezza (scala) | Aggancio | Rotazione | Note |
|---|---|---|---|---|
| Home, pomello del cursore velocità | 30 (0,75) | 15 sopra il centro del pomello | −15° | si muove con il pomello, sparisce con il cursore a obiettivo raggiunto |
| Home, vignetta «OBIETTIVO RAGGIUNTO FATTO!» | 44 (1,1) | angolo alto-sinistro della vignetta + (18, 2) | −20° | dentro la stessa rotazione −5° della vignetta |
| Storico, fiamma grande | 72 (1,8) | (75, 30) nel riquadro 150 × 184 della fiamma | −10° in più | dentro lo `ZStack` della fiamma, quindi ruota anche di −12° con lei |
| Festa dell'obiettivo (`GoalCelebration`) | 64 (1,6) | (100, 22) nel riquadro 320 × 180 della stella | −18° | entra con la stella (stessa molla `pop`) |
| Splash | livello `SplashHat` (sotto) | come l'icona | — | |

## 4. Decorazioni

### 4.1 Home
**Neve che cade** (`SnowLayer`), sopra l'illustrazione e la gamba, sotto tutte le scritte, il cursore e la barra in alto.
- Area: tutto il telaio 390 × 844. Fiocchi: notte **34**, giorno **26**, generati con seme fisso `0x5A17A`.
- Raggio: 1,5 / 2 / 2,5 pt (cerchi pieni) e 3,5 pt (stellina a 6 bracci lunghi 7 pt, tratto 1,2, punte tonde),
  pesi 4 : 3 : 2 : 1. Colore `snow`, opacità a caso tra 0,55 e 0,95.
- Caduta lineare a **22 + 10 × raggio** pt/s (i fiocchi grandi più veloci); spostamento laterale a seno, ampiezza 8 pt,
  periodo 4 s ± 1 s, fase a caso. Uscito sotto y 844 rientra da y −10 alla stessa x.
- `TimelineView(.animation(minimumInterval: 1/30))` + `Canvas`; ferma con l'app non attiva (come la parallasse).
- **Riduci movimento**: stessi fiocchi fermi nella posizione di t = 0.

**Luci sulla strada**: 14 lampadine lungo `SpeedTrack.road`, a lunghezza d'arco (i + 0,5)/14, sopra l'illustrazione,
**sotto la gamba** (la gamba le copre dove passa) e sotto il pomello. Posizioni in pt (già convertite, ×390/881, +54):
(36,0; 801,5) (63,7; 794,2) (90,1; 787,8) (118,0; 781,5) (145,7; 775,8) (173,2; 770,6) (200,3; 766,0) (227,8; 761,3)
(254,7; 755,1) (281,1; 746,2) (304,8; 731,9) (313,2; 706,1) (303,7; 680,6) (278,9; 667,8).
- Lampadina: ellisse 6 × 9 col centro nel punto; attacco 4 × 2,5 `ink` subito sopra. Colori a giro `red`, `gold`, `pine`
  (la prima rossa). Di notte alone: ombra dello stesso colore, raggio 5, opacità 0,8; di giorno nessun alone.
- Lampeggio: opacità 1 ↔ 0,35, `.easeInOut(duration: 1.2).repeatForever(autoreverses: true)`, ritardo
  (i mod 3) × 0,4 s. **Riduci movimento**: accese fisse, opacità 1.

**Cappello** sul pomello e sulla vignetta «FATTO!» (§3). I testi della Home non cambiano.

### 4.2 Storico
- **Cappello** sulla fiamma grande (§3).
- **Neve ferma** nella zona della serie (0–560): 18 fiocchi, colore `snow`, opacità 0,8, sotto il numero e le scritte.
  (x, y, raggio): (95,304,2,5) (354,266,1,5) (235,506,3,5★) (103,133,3,5★) (211,307,3,5★) (248,87,2) (336,293,1,5)
  (260,39,1,5) (119,21,2,5) (185,401,3,5★) (277,512,3,5★) (282,322,2) (340,58,2) (193,146,3,5★) (302,476,3,5★)
  (198,217,2,5) (208,229,2) (349,380,1,5). ★ = stellina. Ferma sempre (la pagina scorre: niente animazione).

### 4.3 Splash
Nuovo livello `SplashHat` (imageset, i due SVG `cappello-rosso.svg` + `cappello-bianco.svg` uniti sulla stessa tela
2048 × 2048 dell'icona) disegnato sopra `SplashShoe` con la stessa cornice e le stesse trasformazioni: il cappello
cade e batte con la scarpa. Con Riduci movimento compare con l'immagine ferma. Il fondo resta #0C0C0C (`iconBlack`),
uguale alla schermata di avvio statica.

### 4.4 Festa dell'obiettivo
Cappello sulla stella (§3); scintille con i colori `[red, ink, pine, gold]` invece di `[red, ink]`. Testi uguali.

### 4.5 Widget (piccolo e medio, schermata Home di iOS)
Solo neve ferma, colore `snow`, opacità 0,8, sopra l'illustrazione e sotto le scritte. Il widget legge l'interruttore e
il periodo dallo `SharedStore` (App Group). Blocco schermo: nessun cambio.
- Piccolo (spazio 170 × 170): (26,141,1,5) (45,84,2) (81,65,1,5) (19,9,2) (74,127,1,5) (117,47,1,5) (100,21,2) (9,8,2,5)
- Medio (spazio 364 × 170, solo la metà sinistra con l'illustrazione): (159,158,1,5) (19,62,1,5) (123,112,2) (45,38,1,5)
  (98,30,2) (107,134,2,5) (158,92,2) (85,150,1,5) (63,155,2) (73,147,1,5)

## 5. Interruttore in Impostazioni
Sezione **«Tema»** (`set.theme.section`), sotto il selettore Sistema/Orario/Giorno/Notte e sopra la nota attuale:
- `Toggle` «**Temi stagionali**» (`set.season.toggle`), `.tint(Theme.accent)` come il promemoria; **acceso di serie**;
  chiave `stepteller.seasonal` (Bool, App Group, così la leggono anche i widget).
- Nota sotto, stessa forma di `note(_:)`: «**Dal 1° dicembre al 6 gennaio: neve, luci e l'icona di Natale. Quando
  l'icona cambia, iOS mostra un avviso.**» (`set.season.note`)

## 6. Icona di Natale
File pronti: `T-004-natale/AppIconNatale.icon/` (Icon Composer: `icon.json` + 5 SVG 2048 × 2048). Anteprime
1024 × 1024: `icona-natale-1024.png` (normale), `icona-natale-tinta-1024.png` (simulazione tinta).

| Gruppo (dal davanti) | Livello | Colore | Vetro | Tinta |
|---|---|---|---|---|
| Cappello | `cappello-bianco.svg` (bordo + pon-pon) | #FFFFFF | no | opacità 0,6 |
| Cappello | `cappello-rosso.svg` (cono) | #E5231B | sì | grigio 1,0 |
| Suola | `rosso.svg` (uguale all'icona attuale) | #E5231B | sì | grigio 1,0 |
| Scarpa | `bianco.svg` (uguale) | #FFFFFF | no | opacità 0,6 |
| Neve | `neve.svg` (8 punti, raggio 26 e 38) | #FFFFFF | no | opacità 0,6 |

Fondo #0C0C0C come l'icona attuale. **Varianti**: chiara, scura e trasparente («clear») le genera Icon Composer dagli
stessi livelli, come per l'icona attuale (che specializza solo la tinta); la tinta è nella tabella. Il pon-pon resta
dentro la maschera arrotondata (verificato: margine 18 px su 2048).

Cambio dell'icona (D-037, API di sistema `setAlternateIconName`, con il suo avviso):
- A ogni ritorno in primo piano, il controllo parte solo quando **sullo schermo non ci sono la festa dell'obiettivo né
  pop-up (T-005) da almeno 0,6 s**, contando dalla fine dello splash; vale anche alla fine dell'introduzione, quindi
  l'avviso di iOS non si sovrappone mai a una festa o a un pop-up (correzione T-013). Allora: se interruttore acceso e
  data nel periodo e icona attuale ≠ `AppIconNatale` → `setAlternateIconName("AppIconNatale")`. Se fuori periodo o
  interruttore spento e icona attuale ≠ nessuna → `setAlternateIconName(nil)`.
- Spegnendo l'interruttore l'icona torna subito quella normale (iOS mostra l'avviso).
- Se l'app non si apre dopo il 6 gennaio, l'icona resta natalizia fino alla prima apertura: limite di iOS, accettato.

## 7. Testi nuovi (da tradurre in 10 lingue)
| Chiave | Italiano |
|---|---|
| `set.season.toggle` | Temi stagionali |
| `set.season.note` | Dal 1° dicembre al 6 gennaio: neve, luci e l'icona di Natale. Quando l'icona cambia, iOS mostra un avviso. |

## 8. Schema per le stagioni successive (un solo meccanismo)
Ogni stagione è un valore di `Season` con gli stessi campi; il codice delle viste non cambia da una stagione all'altra.

| Campo | Natale | Esempio futuro (da progettare) |
|---|---|---|
| `id` | `christmas` | `halloween` |
| periodo (inizio, fine inclusi) | 1/12 – 6/1 | 24/10 – 1/11 |
| `SeasonPalette` (3 token giorno/notte) | snow, gold, pine | foglie, arancio, viola |
| particelle (tipo, numero giorno/notte, velocità) | neve 26/34, 22 + 10r pt/s | foglie 14/18, più lente |
| luci sulla strada (sì/no, colori) | sì, red/gold/pine | sì, arancio/viola |
| accessorio (forma, posizioni della tabella §3) | cappello | cappello da strega, stesse posizioni |
| icona alternativa | `AppIconNatale` | `AppIconHalloween` |
| nota in Impostazioni | `set.season.note` | una chiave per stagione |

Le posizioni dell'accessorio (§3) sono le stesse per ogni stagione: cambia solo la forma.

## 9. Cosa resta aperto
- Debug per gli screenshot: un argomento di avvio che forzi la stagione (es. `-stepteller.season christmas`), a carico
  del Developer.
- L'Apple Watch (1.3) non è in questo tema.
