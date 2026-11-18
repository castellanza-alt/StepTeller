# T-018 Correzioni dal collaudo del Natale (T-017)
**Assegnato a:** Developer (punto 6: Designer) **Base:** `main` 434c97a **Stato:** assegnato 18/11/2026 — urgente,
PR entro il 21/11: dopo si fa la build TestFlight per William

## Perché
Il collaudo T-017 (`comms/qa/T-017.md`, screenshot in `comms/qa/T-017/`) ha trovato un difetto bloccante e alcuni
minori. Decisioni del Director su ognuno qui sotto: si correggono tutti tranne le «osservazioni» del rapporto.

## Developer (ramo `task/T-018-correzioni`, worktree `/Volumes/SSD/Developer/neat-dev`)
1. **Icona di Natale ingrandita (bloccante, difetto 1).** Sulla schermata Home si vede solo un pezzo di suola. Causa
   probabile: `AppIconNatale.icon` con PNG da 2048 px dove `AppIcon.icon` ha SVG. Correggi (dimensioni/scala in
   `icon.json` o livelli rifatti alla misura giusta; se servono SVG, chiedi a me e li faccio fare al Designer) e
   verifica sul Simulatore che l'icona intera corrisponda all'anteprima `docs/design/T-015-natale/icona-natale-1024.png`
   (suola, risvolto di pelliccia, pantalone), nelle varianti giorno, notte e tinta.
2. **Bande laterali sull'SE (difetto 2).** L'illustrazione di Natale deve arrivare ai bordi su tutti i telefoni
   (riempimento, non bande); verifica che la strada e il cursore restino allineati.
3. **Conti dei Jolly nella coda (difetto 3).** Ogni pop-up mostra il conto a quel punto della coda, non il totale
   finale: regalo «ora hai 3» → guadagnato «ora hai 4»; regalo «ora hai 4» → usato «ti restano 3». Test nel nucleo se
   il conto passo per passo nasce lì.
4. **Pomello che a 10 km/h copre «≈ km» fuori stagione (difetto 4)**, nato con D-042: a 10 km/h, su SE e 17 Pro Max,
   il pomello non deve coprire minuti né km (stessa soluzione del Natale o un'altra pulita).
5. **«SALUTE» sulla luna di notte senza dati (difetto 5)**: leggibile, per esempio con lo stesso alone di «MINUTI».
6. **Slitta che a 3 km/h esce dal bordo sinistro (difetto 7)**: resta tutta dentro lo schermo.
7. Riga nel CHANGELOG; `swift test`, Debug e Release; screenshot prima/dopo di ogni punto nella PR; revisione
   indipendente del diff; PR verso `main`, non unirla.

## Designer (ramo `design/T-018-regalo`, worktree `/Volumes/SSD/Developer/neat-design`)
8. **Bordo quadrato dell'illustrazione del regalo (difetto 6)**: ritaglia `RegaloJolly` @2x/@3x così che i tratteggi
   sfumino o seguano la forma, senza bordo dritto; nessun credito Higgsfield se si può fare in locale. PR verso `main`
   con i soli asset (il Developer li prende dopo), non unirla.

## Disco
Solo SSD: file pesanti in `/Volumes/SSD/Temp/NEAT/`, cancellati a fine compito; a fine turno niente acceso.

## Non fare
Non unire, nessuna build TestFlight, nessun tag, nessuna chiave. Non scrivere a William.

## Esito
**Designer, 18/11/2026: punto 8 fatto.** `RegaloJolly` @2x/@3x rifatti in locale dall'originale della generazione #10,
senza crediti, in `docs/design/T-015-natale/asset/`.
- I tratteggi dello scoppio sfumano a zero verso i lati alto e destra, entro 230 px su 1024. Il nastro e la fiamma rossi
  restano pieni.
- Pacco e coperchio non cambiano.
- Le misure restano 300 × 296 e 450 × 444, con il disegno centrato su fondo trasparente: la cornice di 128 × 126,3 pt in
  `JollyPopup` va bene così com'è.
- Il Developer deve solo copiare i due PNG in `App/Assets.xcassets/RegaloJolly.imageset/`.
**18/11/2026, Developer.** Fatto sul ramo `task/T-018-correzioni`, PR https://github.com/castellanza-alt/StepTeller/pull/47 verso `main`, non unita. Screenshot prima/dopo
in `tasks/T-018/`.
1. **Icona di Natale**: i livelli PNG da 2048 px erano letti come 2048 pt su una tela da 1024. In `icon.json` ogni
   livello ha `"position": {"scale": 0.5}`.
   - Compilata con `actool`, è uguale a `icona-natale-1024.png`.
   - Sul Simulatore è intera sulla Home chiara e scura e nell'avviso di iOS.
   - La tinta non si prova sul Simulatore.
   - Se il Director preferisce gli SVG del Designer, si sostituiscono e la scala si toglie.
2. **Bande sull'SE**: a Natale, dietro la tela, la stessa scena allargata solo in orizzontale, ferma e sfumata. È
   disegnata fuori dalla tela, nei punti dello schermo. Strada e cursore restano su quella vera; sui telefoni larghi
   non viene disegnata.
3. **Conti nella coda**: `StreakEvents.stepCounts` nel nucleo, con 5 test. L'ultimo pop-up mostra i Jolly di adesso,
   ognuno prima di lui quelli prima del pop-up successivo.
   - Il regalo si chiede insieme agli eventi dello stesso controllo, con un solo «app attiva»: prima poteva arrivare
     dopo «usato».
   - Si ricontano tutti i pop-up in attesa, tranne quello sullo schermo.
   - Simulatore: regalo 5 → usato 4 (Home 4); regalo 3 → guadagnato 4 → festa.
4. **Pomello a 10 km/h**: il blocco dei minuti sale di 22 pt anche fuori stagione (46 con la slitta). Il pomello non
   copre i km a 10 km/h né a 6 mph, su SE e 17 Pro Max.
5. **«SALUTE» sulla luna**: alone `paper` sulla riga del percorso, come «MINUTI».
6. **Slitta a 3 km/h**: si sposta un poco avanti lungo la strada e sale con essa, fino a restare a 10 pt dal bordo.
8. Asset del regalo del Designer (#45) copiati; il pop-up non ha più il bordo quadrato.

- `swift test`: 117 test verdi. Debug e Release ok.
- Revisione indipendente, corretti:
  - il riempimento allungato anche in verticale;
  - il riempimento disegnato su tutti i telefoni e a ogni movimento;
  - i conti con una coda già in attesa;
  - la slitta spostata che non saliva con la strada.
- Da guardare: il blocco dei minuti più in alto di 22 pt anche fuori stagione è un piccolo cambio della Home normale
  (Director o Designer).

