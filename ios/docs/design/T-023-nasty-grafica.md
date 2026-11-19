# T-023 — NASTY: il cuore, il fumetto e le schermate nuove

**D-047 (19/11/2026, William).** In italiano il terzo livello si chiama **«Senza pietà»**: i livelli sono Normale ·
Piccante · Senza pietà. «NASTY» resta il nome interno di file e compiti, ed è quello usato sotto per il livello.
**Di serie l'app parte su Senza pietà,** anche per chi aggiorna dalla 1.2: niente avviso, cuore e fumetto in Home
subito; spariscono solo con Normale.

**Designer, 19/11/2026.** Da approvare da William sulla tela:
https://claude.ai/artifact/AVJ8rdN4Jpd6nAbZzzcHeF (7 tavole). Progetto: `T-022-nasty-progetto.md`; regole: D-044,
D-045; battute: `T-021-nasty/catalogo/catalogo-approvato.md`. Nessun testo nuovo: le battute sono quelle approvate;
gli altri testi dell'interfaccia sono quelli di `T-026-nasty-testi.md` §1. I cuori sono approvati da William (19/11).

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

## 3. Le animazioni (tavola 2, che si può provare)
William, 19/11: «vorrei che fossero fatti animati in modo tale che il cuore possa battere quando è presente e anche
avere delle animazioni interessanti quando viene toccato o quando parla». I disegni approvati non cambiano: sono
divisi in livelli che, sovrapposti, rifanno esattamente `cuore-*.svg`.

### 3.1 Livelli (`T-023-nasty/livelli/`)
Tutti hanno la stessa tela, viewBox 2048 e 256 × 256 pt, quindi si impilano senza spostamenti. Le varianti `-notte`
hanno il bordo #E2EAFF, gli altri livelli valgono per giorno e notte. Ordine dal basso:

| Livello | Piccante | NASTY |
|---|---|---|
| 1 | `piccante-punte-giorno/notte`: corona di punte con l'anello nero; il buco sta sotto il corpo | `nasty-schegge-giorno/notte`: le 5 schegge staccate |
| 2 | `piccante-corpo`: cuore, bordo rosso, ombra | `nasty-corna-giorno/notte`: corna più la fascia esterna della sagoma |
| 3 | `piccante-lucido`: le due lune bianche | `nasty-corpo`: cuore nero e contorno rosso, senza crepe né lucido |
| 4 | — | `nasty-crepe`: solo le crepe rosse |
| 5 | — | `nasty-lucido`: le due lune bianche |

In SwiftUI ogni livello è un `Image` vettoriale nello stesso frame quadrato (`ZStack`), con le sole trasformazioni
`scaleEffect`, `rotationEffect`, `offset`, `opacity`, `brightness` e `shadow`. Niente sfocature grandi, video o
librerie: a 120 Hz basta un `drawingGroup()` sul cuore intero. Le animazioni a tappe sono `keyframeAnimator`; il battito
è `phaseAnimator`, oppure `TimelineView(.animation)` con una funzione del tempo. L'origine di tutte le trasformazioni
è il centro del quadrato, salvo dove è scritto diverso. Nella tavola il cuore è da 200 pt e gli spostamenti in pt sono
pensati per quella misura: in Home (64 pt) vanno scalati per 64/200.

`k` è la rabbia: vale 1, poi 1,35 al secondo tocco e 1,7 al terzo, se i tocchi arrivano entro 4 s l'uno dall'altro.
Moltiplica gli spostamenti e le rotazioni del tocco. Dopo 4 s senza tocchi torna a 1.

### 3.2 A riposo (sempre, con l'app in primo piano)
- **Piccante:**
  - battito: ciclo di 1,2 s (50 al minuto), `easeInOut`. Scala 1 → 1,07 al 10% → 1 al 20% → 1,04 al 30% → 1 al 42%,
    poi fermo;
  - punte: respirano in 2,4 s, `easeInOut`, in modo continuo. Scala 1 → 1,06 e rotazione 0 → +3° a metà ciclo, poi
    ritorno; il ciclo è indipendente dal battito;
  - arrabbiato (`k` > 1): ciclo di 0,9 s.
- **NASTY:**
  - battito: ciclo di 0,85 s (70 al minuto), lineare, più secco. Scala 1 → 1,09 all'8% (con `offset` x −1,5) → 0,99
    al 15% (x +1,5) → 1,06 al 23% (x −1) → 1 al 33%, poi fermo;
  - crepe: si accendono con ogni colpo. `brightness` +0,9 e `shadow` #FF3B30 di raggio 7 all'8%, di nuovo 0,6 e
    raggio 5 al 23%, spente al 40%;
  - arrabbiato: ciclo di 0,6 s e crepe sempre accese, che pulsano tra +0,7 e +1,1 di `brightness`.

### 3.3 Quando parla (esce o cambia una battuta): 0,7 s
Si legge come «sta parlando lui»: il cuore si carica e spara il fumetto.
- **Cuore Piccante,** curva `easeOut`: (0,9 × 1,08) al 15% → 1,18 al 35% → 0,95 con x −4 al 50% → 1,03 al 70% →
  fermo. Le punte scattano a 1,22 e −4° al 30%, poi tornano.
- **Cuore NASTY,** curva `easeOut`:
  - 0,88 × 1,1 al 15%;
  - dal 30% al 62% trema di rabbia: scala da 1,2 a 1,04, rotazione ±3° e x ±2 che si alternano ogni 6% del tempo;
  - 0,97 al 72%, poi fermo.
- **Crepe di NASTY:** `brightness` +1,2 con `shadow` di raggio 10 dal 30% al 70%.
- **Schegge di NASTY:** volano via (scala 1,7, +25°, opacità 0) tra il 30% e il 70%; poi ricompaiono al loro posto
  (scala 0,6 → 1, opacità 0 → 1).
- **Il fumetto** parte dal centro del cuore:
  - fino al 32% resta nascosto, a scala 0,2, dentro il cuore;
  - al 55% è al suo posto a 1,08, con un piccolo superamento in avanti (+6, −4);
  - 0,97 al 70%, poi fermo;
  - curva `timingCurve(0.2, 0.9, 0.3, 1.2)`.
- **Aptica:** Piccante `.soft`. NASTY `.rigid` al 30% e di nuovo al 50%.

### 3.4 Quando lo tocchi
Una reazione a ogni tocco, a rotazione. Dopo la reazione, a 0,3 s, entra una battuta «Se tocchi il cuore» (comparsa
0,25 s: scala 0,6 → 1). Le reazioni della prova non dipendono dal livello di rabbia; dipende solo `k`.
- **Piccante** (aptica `.impact(.medium)`; con `k` 1,7 `.impact(.heavy)`):
  1. **Riccio,** 0,6 s, molla `timingCurve(0.2, 1.6, 0.4, 1)`: le punte scattano fuori a 1 + 0,3·`k` al 12%,
     restano a 1 + 0,27·`k` fino al 40%, poi rientrano. Il corpo si rannicchia a 0,9.
  2. **Si scansa,** 0,6 s, molla `timingCurve(0.3, 1.4, 0.5, 1)`: tutto il cuore scarta a destra di 30·`k` e ruota
     di +12°·`k` al 18%, resta così fino al 50%, rimbalza a (−3, −2°) all'80%, poi torna.
  3. **Sbuffa,** 0,7 s, `easeOut`: si gonfia a 1 + 0,12·`k` al 30%, si sgonfia a 0,94 al 45%, poi 1,02 e fermo.
     Dalla gobba escono tre sbuffi: ovali 30 × 24 pt con fondo `paper` e bordo `ink` 2,5. Compaiono al 55% e salgono
     di 70 pt allargandosi (−40, 0, +40) mentre spariscono.
- **NASTY** (aptica `.impact(.heavy)`; la cornata ha in più `.rigid` all'impatto):
  1. **Si spacca e si ricompone,** 0,65 s, molla `timingCurve(0.3, 1.5, 0.5, 1)`. Corpo, crepe e lucido sono
     disegnati due volte, ognuna con una maschera a zig-zag lungo la crepa centrale (punti in % del lato: 52/0, 49/22,
     55/38, 46/55, 53/72, 50/100).
     - Metà sinistra: (−8·`k`, +3) e −6°·`k` al 15%, così fino al 45%, poi (+1, 0) e +1° al 70%, poi ferma.
     - Metà destra: lo stesso, a specchio.
     - Le crepe lampeggiano: `brightness` +1,2.
  2. **Cornata,** 0,7 s, `timingCurve(0.4, 0, 0.2, 1)`:
     - carica: −14°·`k` e (−6, +4) al 25%;
     - colpo: +18°·`k` e (+14·`k`, −10) al 40%;
     - due scosse: 14° al 48%, 18° al 56%;
     - ritorno.
  3. **Si gira di scatto,** 0,8 s, `timingCurve(0.2, 0.8, 0.3, 1)`:
     - al 12% si specchia (`scaleEffect(x: −1)`), ruota di −6° e si sposta di x +8; la luce bianca passa dall'altra
       parte, quindi si legge come «girato di spalle»;
     - resta girato con un tremito (−4°/−7°) fino all'80%;
     - all'88% torna dritto con un piccolo 1,05;
     - fermo al 100%.
  4. **Crepe che lampeggiano,** 0,7 s, lineare: tre lampi (`brightness` +1,4 e `shadow` di raggio 12 al 10%, al 40% e
     al 70%), con un sobbalzo 1,06 → 0,98 → 1.
- **Più tocchi, più rabbia.** Si contano i tocchi degli ultimi 4 s:
  - secondo tocco: `k` 1,35;
  - terzo tocco: `k` 1,7, battito arrabbiato (§3.2), aptica più forte.

### 3.5 Riduci movimento
Solo dissolvenze:
- niente battito, respiro, schegge, maschere né spostamenti;
- battuta nuova: il fumetto entra in dissolvenza in 0,2 s;
- tocco: il cuore lampeggia (opacità 0,55 → 1, 0,2 s), poi la battuta entra in dissolvenza;
- l'aptica resta.

### 3.6 Accessibilità
Il cuore è un pulsante. Etichetta: «NEAT. Tocca per un'altra battuta.» (T-026). Il testo della battuta si legge come
valore.

## 4. Introduzione e prima battuta (tavola 5)
- **Pagina nuova** dopo quella dell'obiettivo: le pagine diventano 5. **Di serie è scelto Senza pietà** (D-047) e non
  c'è nessun avviso.
- **Disegno in alto:** l'esplosione rossa con il contorno nero (come `GoalBurst`), con sopra i due cuori:
  - 17 Pro Max: disegno alto 300; cuori da 120 (Piccante, −10°) e 160 (Senza pietà, +8°);
  - SE: disegno alto 168; cuori da 74 e 100.
- **Testi**, come nelle altre pagine:
  - etichetta rossa «VOCE»;
  - titolo «Vuoi che te lo dica gentilmente o che te lo dica davvero?», con `TitleText`: Anton 31, su SE 24, 3 righe.
- **Tre scelte** in colonna: Normale · Piccante · Senza pietà.
  - Righe alte 56 (SE 44), Anton 22 (SE 19), bordo `ink` 2,5, inclinate −8°.
  - Nella riga, a sinistra, il cuore piccolo (34, SE 28); per Normale una lineetta.
  - La riga scelta ha fondo `ink`, testo `paper` e ombra `red` (4, 4). «Senza pietà» ci sta su una riga anche su SE.
- **Sotto le scelte,** in testo di sistema 14 (SE 12), grigio: «Parolacce e insulti compresi. Si cambia quando vuoi in
  Impostazioni › Voce.»
- **Prima battuta dopo l'aggiornamento dalla 1.2,** una volta sola: «Da oggi parlo. Se non reggi: Impostazioni ›
  Voce.» Sta nello stesso posto del fumetto (§2), ma si fa notare di più:
  - fondo `red` pieno e testo `paper` (`MangaPalette.onRed`), Anton 19;
  - bordo `ink` 3, ombra `ink` (5, 5), largo 228, ruotato −5°;
  - cuore a 74 pt invece di 64;
  - sette linee di richiamo `ink` (spessore 3, lunghe 16–20) a raggiera attorno al fumetto;
  - entra con l'animazione «quando parla» (§3.3) a velocità dimezzata, in 1,4 s, con l'aptica `.rigid` doppia;
  - resta finché non cambia la situazione;
  - si segna come già mostrata solo dopo che è comparsa davvero in Home (non al lancio in sottofondo);
  - chi installa da zero non la vede: per lui c'è la pagina dell'introduzione.

## 5. Impostazioni › Voce (tavola 6)
- Sezione nuova **VOCE**, subito dopo l'obiettivo. Di serie è scelto Senza pietà.
- In cima alla scheda: il cuore del livello (40) e il suo nome in Anton 22. In Normale né cuore né nome.
- Sotto: il controllo a tre Normale · Piccante · Senza pietà, lo stesso del Tema.
  - Su SE ogni segmento è largo circa 103 pt e «Senza pietà», in testo di sistema 13 semibold, ne occupa circa 75.
    Quindi ci sta: niente menu.
  - Con il testo grande di Accessibilità vale quello che fa già iOS per il Tema.
- Con Piccante o Senza pietà, sotto una linea, compare la manopola **Poche · Normali · Tante** (di serie Normali) con
  la sua etichetta. In Normale la manopola non compare.
- Nota grigia sotto la scheda: «Piccante: sarcasmo. Senza pietà: parolacce e insulti. NEAT commenta i tuoi passi
  nell'app e nelle notifiche. Normale: NEAT sta zitto.»
- Nessun avviso nel passaggio da un livello all'altro.

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
| Fumetto in Home (175 battute, notifiche escluse) | 3 righe al massimo | ci stanno tutte; quelle da 3 righe sono 18 Senza pietà e 6 Piccante |
| Pop-up | 3 righe al massimo | ci stanno tutte |
| Titolo della festa | 2 righe | ci stanno tutte; solo N121 scende ad Anton 24 (0,8) |
| Riga sotto l'obiettivo | — | la più lunga ha 60 caratteri, 2 righe |

Nessuna battuta va scartata per lo spazio. Con numeri più lunghi (passi a 5 cifre, serie oltre 100) può aggiungersi una
riga solo dove già c'è margine.

## 7. Testi dell'interfaccia
Sono quelli di `T-026-nasty-testi.md` §1, raccolti dal Director, e sono già sulla tela:
- scelte «Normale» · «Piccante» · «Senza pietà» e la riga sotto;
- prima battuta dopo l'aggiornamento;
- sezione «Voce», con la sua nota;
- manopola «Notifiche di NEAT» · «Poche» · «Normali» · «Tante», cioè al giorno Senza pietà 2 · 4–5 · 7 e Piccante 1 · 1–2 · 3;
- VoiceOver del cuore.

L'etichetta rossa dell'introduzione riprende «Voce».

## 8. Screenshot dello store (dopo l'approvazione della tela)
La Home di serie cambia perché ci sono il cuore e il fumetto. Dei 6 screenshot (`store/screenshots/<lingua>/01…06.jpg`):

| N. | Cosa mostra | Cambia? |
|---|---|---|
| 01 | Home di giorno, «Quanti passi hai fatto oggi?» | **sì**: cuore e fumetto |
| 02 | Home di notte e riquadro dei minuti, «Quanti te ne mancano?» | **sì**: cuore e fumetto. In più oggi mostra 16 km/h, che dalla 1.2 non esiste più (massimo 10, D-042) |
| 03 | Due ritagli della strada col pomello, «Quanto devi ancora camminare?» | i ritagli stanno sotto il fumetto, quindi il disegno non cambia; ma il secondo mostra 16,0 km/h, da rifare a 10 o meno |
| 04 | Storico e serie | no: lo Storico resta com'è |
| 05 | Widget | no: i widget restano come sono |
| 06 | Privacy dell'introduzione | no |

Nelle battute degli screenshot niente parolacce: si scelgono tra quelle di Senza pietà che non ne hanno, con i numeri
dello screenshot. Proposte:
- 01, giorno, 3.465 passi: N007 «3.465 passi. Sei un soprammobile con il telefono.»;
- 02, notte: N050 «Pomeriggio. 3.465 passi. Il tempo passa, tu no.» oppure N036 «3.465 passi. Sei l'orgoglio del
  divano.».

Nelle altre lingue: le versioni tradotte delle stesse battute (T-025).

## 9. Higgsfield
Una sola generazione: job `098efe47`, `nano_banana_2_1` 1k, 1,5 crediti. Saldo verificato con `balance`: 13,5 → 12.
I due cuori sono nella stessa immagine, su magenta. Poi, in locale: 5 colori esatti, filtro di moda (7) e potrace.
Prompt esatto:

> Two stylized heart characters side by side, Japanese manga ink illustration, bold black ink outlines, strong volume and 3D roundness rendered with flat cel shading (hard-edged shadow shapes and sharp white highlight shapes, no gradients, no screentone dots, no texture). Only four flat colors: near-black #0C0C0C, white #FFFFFF, vivid red #E5231B, dark red #8E0F0B. NO face, no eyes, no mouth, no limbs. LEFT heart 'spicy': a plump glossy dark-red heart (dark red body, black shadow side, red mid-tone, crisp white highlight crescent on the upper left lobe), surrounded by a jagged crown of sharp black spikes all around its outline like a spiky burst, menacing but clean. RIGHT heart 'nasty': a plump glossy black heart with a thick vivid red outline, two short sharp curved devil horns on top in black with red outline, deep jagged cracks across the body glowing vivid red from inside, white highlight crescent on the upper left lobe, a few small black shards flying off. Both hearts same size, centered in their half, generous margin, on a perfectly flat solid magenta #FF00FF background. Not a medical or health icon, nothing pink, no text, no letters, no frame.
