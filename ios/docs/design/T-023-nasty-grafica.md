# T-023 — NASTY: il cuore, il fumetto e le schermate nuove

**Designer, 19/11/2026.** Da approvare da William sulla tela:
https://claude.ai/artifact/AVJ8rdN4Jpd6nAbZzzcHeF (7 tavole). Progetto: `T-022-nasty-progetto.md`; regole: D-044,
D-045; battute: `T-021-nasty/catalogo/catalogo-approvato.md`. Nessun testo nuovo: le battute sono quelle approvate; i
pochi testi che mancano sono in §7.

Misure in punti della tela della Home (`Manga.frameWidth` 390 × 844, `Manga.artTop` 54), come in `HomeView`. Colori:
token di `MangaPalette` (giorno `paper` #FFFFFF, `ink` #141414, `red` #E5231B; notte `paper` #0E1430, `ink` #E2EAFF,
`red` #FF3B30) più i colori del disegno del cuore, che stanno nel file come quelli dell'icona.

## 1. Il cuore (`T-023-nasty/`)
- Senza volto. Ha volume: lato destro in ombra nera, luce bianca a mezzaluna in alto a sinistra, bordo lucido. Non
  ricorda Salute: niente rosa, niente quadrato bianco, sempre un contorno nero con punte o corna.
- **Piccante:** cuore rosso scuro #7E0F0B dentro un bordo rosso #E5231B, ombra nera, corona di punte nere.
- **NASTY:** cuore nero #0C0C0C, contorno rosso #E5231B, crepe rosse, due corna, schegge che si staccano.
- **Normale:** il cuore non c'è.
- File: `cuore-piccante-giorno.svg`, `cuore-piccante-notte.svg`, `cuore-nasty-giorno.svg`, `cuore-nasty-notte.svg`.
  Sono a viewBox 2048 e 256 × 256 pt, quadrati, con solo tracciati pieni. Livelli dal basso: sagoma nera, poi rosso
  scuro, rosso e bianco. Di notte c'è in più un bordo esterno #E2EAFF (`ink` di notte), spesso 36 su 2048, così punte
  e corna si staccano dal blu.
- Nell'app: un imageset con le varianti chiaro e scuro (*Preserve Vector Data*), oppure due immagini scelte con il
  tema dell'app (`MangaTheme`). Il tema dell'app non segue sempre il sistema, quindi la seconda strada è più sicura.
- Misure: **64 pt** in Home, 64 sui pop-up e sulla festa, 26–30 accanto alla riga dell'obiettivo, 34 (SE 28) nelle
  scelte dell'introduzione, 84 nell'avviso, 40 nelle Impostazioni. A 44 pt si legge ancora. Anteprima:
  `anteprima-cuori.png`.

## 2. Il fumetto in Home
- **Posto:** lo spazio degli avvisi (`notices`, oggi a (20, `artTop` + 286)). Quando c'è l'avviso «nessun dato» da
  Salute, vince l'avviso e il fumetto non compare.
- **Cuore:** a (12, 336), 64 × 64.
- **Fumetto:** a (84, 334), largo 210, ruotato −4° attorno al bordo sinistro a metà altezza.
  - Fondo `paper`, bordo `ink` 2,5, raggio 16.
  - Ombra piena spostata di (4, 4):
    - NASTY: `red`;
    - Piccante di giorno: `ink`;
    - Piccante di notte: `ink` al 35%.
  - Padding 9 / 12 / 8 / 12.
  - Coda a sinistra: un quadrato da 15 ruotato di 45°, con i bordi `ink` sui lati sinistro e basso. Esce a 22 pt dal
    bordo alto e punta il cuore.
- **Testo:** Anton 17, maiuscolo, interlinea 1,08, spaziatura 0,02, colore `ink`, al massimo 3 righe in 186 pt.
- **Prove** (tavole 3 e 4): la più corta, una media e la più lunga per livello, su 17 Pro Max e SE, di giorno e di notte.
  - NASTY: N039, N007, N087.
  - Piccante: P058, P008, P024.
  - Il fumetto copre una parte della gamba, come il riquadro «FATTO!»: è voluto, il fondo `paper` lo rende leggibile.
- Quando cambia la battuta, il fumetto si ridimensiona all'altezza nuova (1–3 righe). Il cuore resta fermo.

## 3. Come si muove (tavola 2, che si può provare)
- **Battito lento:** un doppio battito ogni 2,4 s (scala 1 → 1,06 → 1 → 1,035 → 1 nel primo 32% del ciclo, poi
  fermo), attorno al centro. Solo con l'app in primo piano.
- **Sussulto al cambio di battuta:**
  - il cuore, in 0,4 s: (1,16 × 0,88, −6°) → (0,94 × 1,08, +4°) → (1,04, −2°) → fermo;
  - il fumetto, dopo 0,08 s: nasce dalla coda in 0,28 s (scala 0,5 → 1,06 → 1, opacità 0 → 1).
- **Tocco:**
  - il cuore, in 0,5 s: (0,86 × 1,1) → (1,14 × 0,9) → (0,97 × 1,03) → fermo;
  - un anello rosso tratteggiato (diametro da 0,6 a 1,35 volte quello del cuore) si allarga e sparisce;
  - aptica leggera;
  - esce una battuta «Se tocchi il cuore»; un altro tocco entro 3 s non la cambia.
- **Riduci movimento:**
  - niente battito, sussulto né anello;
  - la battuta nuova entra in dissolvenza (0,2 s);
  - al tocco il cuore lampeggia (opacità 0,55 → 1, 0,2 s);
  - l'aptica resta.
- Accessibilità: il cuore è un pulsante. Etichetta: il testo della battuta. Suggerimento: da scrivere (§7).

## 4. Introduzione (tavola 5)
- **Pagina nuova** dopo quella dell'obiettivo: le pagine diventano 5. Di serie è scelto Normale.
- **Disegno in alto:** l'esplosione rossa con il contorno nero (come `GoalBurst`), con sopra i due cuori:
  - 17 Pro Max: disegno alto 330; cuori da 130 (Piccante, −10°) e 170 (NASTY, +8°);
  - SE: disegno alto 196; cuori da 84 e 110.
- **Testi**, come nelle altre pagine:
  - etichetta rossa «VOCE»;
  - titolo «Vuoi che te lo dica gentilmente o che te lo dica davvero?», con `TitleText`: Anton 31, su SE 25, 3 righe.
- **Tre scelte** in colonna:
  - righe alte 56 (SE 46), Anton 22 (SE 19), bordo `ink` 2,5, inclinate −8°;
  - nella riga, a sinistra, il cuore piccolo (34, SE 28); per Normale una lineetta;
  - la riga scelta ha fondo `ink`, testo `paper` e ombra `red` (4, 4).
- **Avviso prima di NASTY:** compare toccando Continua con NASTY scelto.
  - Riquadro come i pop-up dei Jolly: largo 340, bordo 3, ombra `red` (6, 6), ruotato −2°, con il velo `paper` al 72%.
  - Dentro: il cuore NASTY da 84, poi «Parolacce e insulti. L'hai voluto tu.» in Anton 30, con la seconda frase in
    `red`.
  - Due tasti: uno a bordo, uno rosso (§7).
  - «Annulla» torna alla pagina con Piccante scelto.

## 5. Impostazioni › Voce (tavola 6)
- Sezione nuova **VOCE**, subito dopo l'obiettivo.
- In cima alla scheda: il cuore del livello (40) e il suo nome in Anton 22. In Normale né cuore né nome.
- Sotto: il controllo a tre Normale · Piccante · NASTY, lo stesso del Tema.
- Con Piccante o NASTY, sotto una linea, la manopola **Poche · Normali · Tante** (di serie Normali) con la sua
  etichetta. In Normale la manopola non compare.
- Nota grigia sotto la scheda (§7).
- Passare a NASTY dalle Impostazioni mostra lo stesso avviso dell'introduzione.

## 6. Gli altri punti dove parla (tavola 7 e tavola 6)
- **Riga sotto l'obiettivo** (introduzione e Impostazioni, quando lo scegli o lo cambi): una battuta di «Obiettivo
  scelto o cambiato» sotto il numero.
  - Anton 15, `red`, maiuscolo, interlinea 1,1.
  - A sinistra il cuore da 26–30.
  - La nota grigia di sempre scende sotto.
  - Resta finché chiudi la pagina o le Impostazioni.
- **Pop-up di Jolly e serie:**
  - la battuta prende il posto della prima frase (`jolly.used.missed`, `jolly.earned.days`), stessa
    `sentence(...)`: Anton 20, al massimo 3 righe;
  - la frase rossa con la serie resta;
  - il riquadro cresce verso il basso;
  - il cuore da 64 sta come un adesivo sull'angolo in alto a destra, ruotato di +10° e a cavallo del bordo.
- **Titolo della festa:**
  - la battuta prende il posto di «OBIETTIVO RAGGIUNTO!»: Anton 30, larga al massimo 330, **2 righe**, centrata;
  - si rimpicciolisce al massimo fino a 0,8;
  - il cuore da 64 sta in alto a sinistra, ruotato −12°.
- **Notifiche:** sono testo di iOS, quindi non hanno grafica; il catalogo le scrive come «titolo / testo».
- **Storico e widget:** restano come sono (T-022).

### Ci stanno?
Ho misurato con Anton e numeri realistici: 3.240 passi, 10.000 di obiettivo, 6.760 mancanti, 67 minuti, 22 giorni.

| Dove | Regola | Esito |
|---|---|---|
| Fumetto in Home (175 battute, notifiche escluse) | 3 righe al massimo | ci stanno tutte; quelle da 3 righe sono 18 NASTY e 6 Piccante |
| Pop-up | 3 righe al massimo | ci stanno tutte |
| Titolo della festa | 2 righe | ci stanno tutte; solo N121 scende ad Anton 24 (0,8) |
| Riga sotto l'obiettivo | — | la più lunga ha 60 caratteri, 2 righe |

Nessuna battuta va scartata per lo spazio. Con numeri più lunghi (passi a 5 cifre, serie oltre 100) può aggiungersi una
riga solo dove già c'è margine.

## 7. Testi che mancano (da scrivere, Director e William)
1. I due tasti dell'avviso di NASTY. Sulla tela la proposta è «Annulla» e «NASTY».
2. L'etichetta della manopola. Sulla tela: «Notifiche di NEAT».
3. La nota sotto la sezione Voce. Sulla tela c'è una bozza presa da T-022.
4. Il suggerimento di VoiceOver sul cuore, per esempio «Tocca per un'altra battuta».
5. L'etichetta rossa «VOCE» dell'introduzione, se il nome della sezione non va bene anche lì.

Poche e Tante: quante notifiche al giorno è una decisione del Director (Normali = T-022).

## 8. Higgsfield
Una sola generazione: job `098efe47`, `nano_banana_2_1` 1k, 1,5 crediti. Saldo verificato con `balance`: 13,5 → 12.
I due cuori sono nella stessa immagine, su magenta. Poi, in locale: 5 colori esatti, filtro di moda (7) e potrace.
Prompt esatto:

> Two stylized heart characters side by side, Japanese manga ink illustration, bold black ink outlines, strong volume and 3D roundness rendered with flat cel shading (hard-edged shadow shapes and sharp white highlight shapes, no gradients, no screentone dots, no texture). Only four flat colors: near-black #0C0C0C, white #FFFFFF, vivid red #E5231B, dark red #8E0F0B. NO face, no eyes, no mouth, no limbs. LEFT heart 'spicy': a plump glossy dark-red heart (dark red body, black shadow side, red mid-tone, crisp white highlight crescent on the upper left lobe), surrounded by a jagged crown of sharp black spikes all around its outline like a spiky burst, menacing but clean. RIGHT heart 'nasty': a plump glossy black heart with a thick vivid red outline, two short sharp curved devil horns on top in black with red outline, deep jagged cracks across the body glowing vivid red from inside, white highlight crescent on the upper left lobe, a few small black shards flying off. Both hearts same size, centered in their half, generous margin, on a perfectly flat solid magenta #FF00FF background. Not a medical or health icon, nothing pink, no text, no letters, no frame.
