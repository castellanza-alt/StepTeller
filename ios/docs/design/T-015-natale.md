# T-015 — Natale rifatto: stivale, neve, slitta, Jolly regalo, icona

Sostituisce **`T-004-natale.md`**, bocciata da William il 18/11. Valgono D-040 e D-037: un solo meccanismo, le date dal 1/12
al 6/1, l'interruttore e l'icona alternativa.

Idea: **l'episodio speciale di Natale dello stesso manga**. La Home resta la stessa scena: la gamba in primo piano con la
parallasse, la strada e il cursore della velocità. Cambia solo il disegno:
- il piede è lo stivale di Babbo Natale;
- dietro c'è un paesaggio innevato;
- sulla strada corre una slitta con le renne.

Niente accessori appiccicati. Storico, splash e widget non hanno un'idea forte, quindi **restano come sono**.

- Tela per William: https://claude.ai/artifact/SZPn4ouqgQdfiDUA7DtZRY. Contiene Home di giorno e di notte, slitta contro
  pomello, pop-up del regalo e icona.
- Asset: `T-015-natale/asset/` e `T-015-natale/AppIconNatale.icon/`.
- Generazioni e crediti: `T-015-natale/generazioni.md`, con 16,5 crediti su 39.

## 1. Quando
- Periodo, interruttore «Temi stagionali» e App Group: come oggi, invariati. Codice di riferimento: `Season`,
  `SeasonalTheme.active()`.
- Fuori periodo, o con l'interruttore spento, l'app è quella normale.
- Il **Jolly regalo** (§4) **non dipende dall'interruttore**: è un regalo, non una decorazione. Se l'interruttore è spento
  il pop-up compare uguale, solo senza tema intorno. Va confermato (§9).

## 2. Home

### 2.1 Livelli (dal fondo; tutto il resto della Home è invariato)

| Livello | Oggi | A Natale | Cornice (pt) |
|---|---|---|---|
| Illustrazione | `c.homeArt` | `HomeNataleDay` / `HomeNataleNight` | 390 × 790 da y 54, come `Manga.artSize` / `artTop` |
| Gamba (parallasse) | `c.homeLeg` | `HomeLegNataleDay` / `HomeLegNataleNight` | uguale a oggi (`ParallaxLeg`): 411,3 × 811,2, spostata di −10,6 / −10,6 |
| Testi, slitta, barra in alto | — | invariati, tranne il pomello (§3) | — |

- **Si tolgono** dalla Home:
  - `RoadLights`;
  - `SnowLayer`;
  - il cappello sul riquadro «FATTO!» (`SeasonAccessory` in `doneBlock`).

  La neve ora è **dentro il disegno**: niente particelle animate.
- La gamba ha lo stesso formato di quella attuale: la tela dell'illustrazione più **24 px-arte ripetuti** su ogni lato
  (`Manga.legPadding`).
  - Restano uguali `Manga.parallaxMax` = 8 pt, `ParallaxMotion` e la regola di «Riduci movimento» (parallasse ferma).
  - `ParallaxLeg` non cambia: riceve solo il nome dell'immagine.
- **Strada e cursore**: `SpeedTrack.road` (spazio 881 × 1786 px) **non cambia**. Ho misurato le nuove illustrazioni
  sovrapponendo il percorso.
  - Di giorno la linea tratteggiata sta entro **10 px-arte (≈ 4,4 pt)** dal percorso, di notte entro 6 px-arte.
  - Sono entrambi dentro i 20 pt di `Manga.trackTouchRadius`.
- Leggibilità:
  - di giorno i testi `ink` restano su cielo e neve chiari, come oggi su carta;
  - di notte il terreno è blu scuro (#0E1430 con tratti #E2EAFF), quindi i testi `ink` di notte (#E2EAFF) si leggono.
    La prima prova di notte, con neve chiara, l'ho scartata per questo motivo.

### 2.2 File (in `T-015-natale/asset/`, da copiare in `Assets.xcassets`)

| Imageset | File | Pixel | Peso | Note |
|---|---|---|---|---|
| `HomeNataleDay` | `HomeNataleDay.jpg` | 1170 × 2370 (@3x di 390 × 790) | 0,63 MB | JPEG, nessuna trasparenza; una sola scala («universal», `preserves-vector-representation` no) |
| `HomeNataleNight` | `HomeNataleNight.jpg` | 1170 × 2370 | 0,57 MB | idem |
| `HomeLegNataleDay` | `HomeLegNataleDay.png` | 1234 × 2434 | 0,35 MB | PNG a 256 colori con trasparenza; stesse proporzioni di `leg-day.png` (929 × 1834) |
| `HomeLegNataleNight` | `HomeLegNataleNight.png` | 1234 × 2434 | 0,36 MB | idem |
| `Slitta` | `Slitta@2x.png`, `Slitta@3x.png` | 184 × 85, 276 × 127 | 0,09 MB | §3 |
| `RegaloJolly` | `RegaloJolly@2x.png`, `RegaloJolly@3x.png` | 300 × 296, 450 × 444 | 0,52 MB | §4 |

- Le immagini attuali di 881 × 1786 erano a ≈ 2,26×; queste sono a 3×. Il codice le usa con `.resizable()` nelle stesse
  cornici in pt, quindi basta cambiare il nome.
- **Totale asset: ≈ 2,5 MB**, più l'icona (0,28 MB).
- Gli imageset di Natale vanno compilati **solo nell'app**: il widget non li usa (§6).

### 2.3 Notte
- Lo sfondo di notte è un'illustrazione a sé (generazione #6).
- La gamba di notte è **ricolorata** da quella di giorno, così le due combaciano al pixel. La regola, applicata pixel per
  pixel su RGB 0…1:
  - `lum = 0,3 R + 0,59 G + 0,11 B`;
  - `base = ink notte #0E1430 + (paper notte #E2EAFF − #0E1430) × lum`;
  - `rossezza = clamp((R − max(G, B)) × 1,6, 0, 1)`;
  - colore finale = `base × (1 − rossezza) + red notte #FF3B30 × (0,35 + 0,65 R) × rossezza`;
  - alfa invariato.

  Il PNG è già pronto: la regola serve solo se un giorno si rifà la gamba.

## 3. Slitta al posto del pomello (proposta; pomello di riserva)

Il pomello rosso (34 pt) diventa la **slitta con due renne**, vuota e in stile adesivo con il bordo bianco. Gira bene sia
di giorno sia di notte, quindi basta un solo asset.
- **Cornice**: 92 × 42,4 pt.
- **Punto di aggancio**: nel riquadro della slitta (27,6; 33,9) pt, cioè sotto i pattini. Va sul punto della strada dove
  oggi c'è il **centro del pomello** (`p` in `RoadSpeedSlider`).
- **Direzione** (tangente `a` della strada in `p`, in gradi, 0 = verso destra, negativi verso l'alto):
  - se la strada va verso destra (`cos a ≥ 0`): slitta dritta, `rotation = clamp(a, −25°, +25°)`;
  - se va verso sinistra (`cos a < 0`, da **≈ 13,6 km/h / 8,5 mph**, l'ultima curva):
    - slitta **specchiata** (`scaleX(−1)`);
    - aggancio in (92 − 27,6; 33,9) = (64,4; 33,9);
    - `rotation = clamp(norm(a − 180°), −25°, +25°)`, dove `norm` porta l'angolo in (−180°, 180°], applicata dopo lo
      specchio. Per esempio a 15 km/h `a ≈ −140°` dà +40°, cioè +25°.
  - In pratica la slitta guarda dove va la strada e si inclina al massimo di 25°.
  - Il passaggio dritta ↔ specchiata usa `.snappy(duration: 0.25)` sulla scala x; con «Riduci movimento» avviene senza
    animazione.
- **Valore** («5,5 km/h», Anton 26 + 15, come oggi): resta accanto alla slitta, con la stessa regola di
  `Manga.knobFlipX` (230 pt).
  - A destra: x = `p.x + 64,4 + 8`.
  - A sinistra (`p.x > 230`): bordo destro del valore a `p.x − 27,6 − 8`.
  - In verticale: centrato su `p.y − 10`.
- **Tocco, trascinamento, aptica e VoiceOver**: invariati. Restano `TrackHitShape` a 20 pt dalla strada,
  `.sensoryFeedback(.selection)`, `home.speed.vo` e l'azione regolabile.
  - La slitta e il valore non ricevono tocchi (`allowsHitTesting(false)`), come oggi il pomello.
  - La scia rossa (`trail`) resta com'è.
- **Niente alone** (`knobGlow`) dietro la slitta: il bordo bianco basta.
- **Pomello di riserva**: se William preferisce, resta il pomello attuale **senza nulla sopra** (niente cappello). La tela
  lo mostra accanto alla slitta.

## 4. Jolly regalo

### 4.1 Regola (D-040)
- **+1 Jolly** alla **prima apertura dell'app** dalle **00:00 del 25/12 (ora locale)** in poi, **fino al 6/1 compreso**.
- Una sola volta per stagione: chi apre l'app il 3 gennaio lo riceve il 3 gennaio.
- Il Jolly si aggiunge a quelli calcolati e vale come gli altri: salva la streak se si salta un giorno.
- «Già dato in questa stagione» va segnato anche in iCloud e nel Backup (D-040), così una reinstallazione non lo ripete.
  Il come lo decide il Director o il Developer.
- Coda dei pop-up (T-005 §1.1): **regalo → usato → guadagnato → festa**. Il regalo viene prima perché è il primo evento
  della giornata.

### 4.2 Pop-up
È la vignetta di T-005 §1.2 per «guadagnato». Valgono le stesse regole:
- velo, raggi, vignetta `panelB` larga 318, centro a y 430, −4°;
- 16 pt di margine sopra il titolo;
- chiusura solo con OK o con un tocco, entrata e uscita come in T-005 §1.3.

Le differenze:

| # | Elemento | Specifica |
|---|---|---|
| a | Titolo | `jolly.gift.title` «JOLLY IN REGALO!», stessi stile e trasformazione del titolo di T-005 |
| b | Illustrazione + numero | riga, `spacing` 6, padding sopra 12: **`RegaloJolly` 128 × 126,3 pt** al posto della `FlameIcon` 78 × 95, poi «+1» `GlyphText` 112 come «guadagnato» (riempito `red`, contorno `ink` 2,5, ombra dura `ink` (5, 5), `manga(rotate: -5, skew: -10)`). L'illustrazione fa lo stesso scossone della fiamma (keyframe −8/+8/−5/0°) |
| c | Frase | `jolly.gift.line` «È NATALE: UN GIORNO DI PAUSA TE LO OFFRIAMO NOI.», Anton 20, come la frase di T-005, al massimo 2 righe |
| e | Targhetta | `jolly.count` (esistente), per esempio «2 JOLLY DISPONIBILI» |
| f | Nota | `jolly.gift.note` «VALE COME GLI ALTRI: SE SALTI UN GIORNO, SALVA LA STREAK.», Anton 14, `ink` all'opacità 0,7 |
| g | Bottone | `jolly.ok` «OK» (esistente) |

- **Aptica**: `.success`.
- **Scintille**: solo `[red, ink]`, perché le tinte `pine` e `gold` si tolgono (§6).
- **VoiceOver**: `jolly.gift.vo`.
- **Di notte**: si usano i token di notte, l'illustrazione è la stessa.

## 5. Icona di Natale (`T-015-natale/AppIconNatale.icon/`)
- Stessa composizione e stesso stile piatto dell'icona attuale: la suola rossa vista da sotto e le scie in basso a
  sinistra. La scarpa diventa **lo stivale**: tomaia nera con tratti bianchi, **risvolto di pelliccia bianca** in alto a
  destra e un pezzo di pantalone rosso. Niente lacci, niente cappello, niente neve.
- Il formato di Icon Composer è lo stesso di `App/AppIcon.icon`:
  - `icon.json` copiato da lì, con il gruppo «Scarpa» rinominato «Stivale»;
  - due livelli PNG 2048 × 2048: `rosso.png` (#E5231B, vetro sì, tinta grigio 1,0) e `bianco.png` (#FFFFFF, vetro no,
    tinta opacità 0,6);
  - fondo #0C0C0C.
- Varianti chiara, scura e trasparente: le genera Icon Composer dagli stessi livelli, come per l'icona attuale.
- Anteprime: `icona-natale-1024.png` e `icona-natale-tinta-1024.png`. Il risvolto resta fuori dagli angoli arrotondati.
- **Va sostituita** l'attuale `App/AppIconNatale.icon` (quella con il cappello). Nome e meccanismo di cambio restano
  quelli di oggi (`SeasonIcon`, T-004 §6 con la correzione di T-013).

## 6. Cosa resta e cosa si toglie nel codice

**Resta**:
- `Season` e `SeasonalTheme`;
- l'interruttore e la sua copia nell'App Group;
- `SeasonIcon`, con la regola dello schermo libero;
- l'ambiente `\.season`;
- `SeasonLook`, il valore unico per stagione. Diventa:
  `SeasonLook(season, homeArtDay: "HomeNataleDay", homeArtNight: "HomeNataleNight", homeLegDay: "HomeLegNataleDay",
  homeLegNight: "HomeLegNataleNight", slider: .sleigh("Slitta"), iconName: "AppIconNatale")`. Le viste leggono i nomi da
  qui e non chiedono mai quale stagione è.

**Si toglie**:

| Cosa | Dove |
|---|---|
| `SeasonAccessory` (cappello) e le sue 6 posizioni | slider, `doneBlock`, Storico, festa, `JollyPopup`, splash (`SplashHat`, imageset da togliere) |
| `SnowLayer`, `StaticSnow` (con le liste di fiocchi) | Home, Storico, widget piccolo e medio |
| `RoadLights` | Home |
| `SeasonPalette` (`snow`, `gold`, `pine`) | non serve più: le scintille della festa e dei pop-up tornano `[red, ink]` |
| `flakesDay` e `flakesNight` in `SeasonLook` | — |

Il file `SeasonDecor.swift` resta senza contenuto e si può cancellare. **Storico, splash e widget** a Natale sono
identici al resto dell'anno.

## 7. «Riduci movimento»
- Parallasse ferma, come oggi.
- La slitta si specchia senza animazione.
- Il pop-up del regalo segue T-005: niente raggi in movimento né scossone, solo dissolvenza.
- Non c'è altro movimento nuovo: la neve è disegnata, non animata.

## 8. Testi (italiano; da far approvare a William, poi al Traduttore, D-041)

| Chiave | Testo | Limite | Dove |
|---|---|---|---|
| `jolly.gift.title` | JOLLY IN REGALO! | ≤ 22 | titolo del pop-up |
| `jolly.gift.line` | È NATALE: UN GIORNO DI PAUSA TE LO OFFRIAMO NOI. | ≤ 50, 2 righe | frase |
| `jolly.gift.note` | VALE COME GLI ALTRI: SE SALTI UN GIORNO, SALVA LA STREAK. | ≤ 60 | nota |
| `jolly.gift.vo` | Jolly in regalo per Natale: più uno. Ora hai %@ Jolly. Se salti un giorno, un Jolly salva la streak. | — | VoiceOver |
| `set.season.note` (**cambia**) | Dal 1° dicembre al 6 gennaio: stivale, neve, slitta e l'icona di Natale. Quando l'icona cambia, iOS mostra un avviso. | come oggi | Impostazioni |

I due testi di T-004 sul cappello non servono più. `jolly.count` e `jolly.ok` esistono già.

## 9. Cosa resta aperto
- **Slitta o pomello**: decide William sulla tela.
- **Regalo con l'interruttore spento**: propongo di sì (§1). Decide il Director.
- **Voce NASTY (T-008)**: se è attiva, il pop-up del regalo potrebbe avere una frase sua. Per ora usa i testi di §8.
- La notte della gamba è ricolorata, non ridisegnata: se William la vuole più scura, basta cambiare la regola di §2.3,
  senza nuovi crediti.
