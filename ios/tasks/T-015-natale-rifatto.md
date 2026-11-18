# T-015 Natale rifatto: stivale, neve, slitta, Jolly regalo, icona (specifica e illustrazioni)
**Assegnato a:** Designer **Base:** `main` aggiornato **Stato:** assegnato 18/11/2026 — **urgente**: prima tela da
mostrare a William entro il 20/11, specifica completa entro il 22/11

## Perché
William ha bocciato il primo Natale (T-004): «ha messo un cavolo di cappellino sulla punta della scarpa. Davvero?
Questo è il massimo che si può fare?». Il problema non era l'esecuzione ma l'idea: accessori attaccati all'app di sempre
invece di un tema. La nuova direzione è sua (D-040, `comms/feedback.md` 18/11). Esce con la 1.2, tutto insieme.

## La direzione (di William, non si discute: si realizza bene)
- **Stessa struttura della Home**: la gamba in primo piano con l'effetto parallasse resta, ma il piede è **lo stivale di
  Babbo Natale** (non la scarpa da corsa). Dietro, **un paesaggio innevato**. Stile «Dan Dan Dan» (inchiostro, retini,
  vignette): è l'episodio speciale di Natale del manga, non un altro stile.
- **Pomello della velocità → slitta trainata dalle renne**, se ci sta: deve restare leggibile e facile da trascinare
  come il pomello (stessa area di tocco, stesso comportamento). Se è brutta o scomoda, resta il pomello (eventualmente
  intonato al tema) e lo scrivi nell'Esito con il perché, mostrando il tentativo.
- **Jolly regalo**: +1 Jolly alla prima apertura dalla mezzanotte della vigilia (25/12 00:00) in poi, fino al 6/1, una
  volta per stagione. Serve un pop-up speciale (sulla base della vignetta Jolly di T-005) con una scritta speciale.
- **Niente riferimenti religiosi**: Babbo Natale, neve, renne, regali sì; presepe, angeli, stelle cometa, croci no.
- **Icona ridisegnata con lo stivale**, varianti come l'icona attuale (giorno, notte, tinta, trasparente).
- **Meno è meglio**: niente cappellini sparsi, niente decorazioni appiccicate su ogni elemento. Ogni cosa natalizia
  deve avere un motivo. Se Storico, splash e widget non hanno un'idea forte, restano come sono con la sola palette.

## Cosa fare (ramo `design/T-015-natale`, worktree `~/Developer/neat-design`)
1. **Illustrazioni vere con Higgsfield** (strumenti `mcp__1f97797c…` già collegati; sì di William alla spesa, D-040):
   stivale/gamba (a livelli separati per la parallasse), paesaggio innevato (a strati: primo piano, medio, fondo),
   slitta con renne, illustrazione del pop-up regalo, icona. **Tetto: i 39 crediti presenti al 18/11; nessuna ricarica,
   nessun piano a pagamento.** Prima di generare, controlla il costo con `balance` e con il preventivo del modello; usa
   prima i modelli economici per le prove, il migliore solo per le versioni finali. Annota ogni generazione (modello,
   prompt, crediti) nella specifica. Niente personaggi o marchi protetti (Babbo Natale «Coca-Cola», personaggi di film).
   Le immagini devono stare nello stile manga in bianco/nero/rosso dell'app: se escono «da cartolina», riprova.
2. **Formato per l'app**: PNG con trasparenza a @2x/@3x (o PDF vettoriale se ha senso), dimensioni in pt, punti di
   ancoraggio per la parallasse, versione giorno e notte (o regola su come la notte le ricolora con i token).
   Peso totale degli asset ragionevole (indica i MB).
3. **Specifica** `ios/docs/design/T-015-natale.md`, che **sostituisce** `T-004-natale.md` (segnalo in testa a quello):
   Home giorno/notte, slitta (o pomello), pop-up del Jolly regalo con testi italiani esatti, icona, cosa succede con
   «Riduci movimento», cosa resta del meccanismo stagionale già nel codice (`Season`, `SeasonPalette`, `SeasonLook`,
   interruttore, cambio icona) e cosa va tolto (neve sparsa, luci, cappelli). Testi nuovi al minimo e tutti elencati.
4. **Tela di Claude Design per William** (D-040, scelta di lavoro con William): pubblica una tela con il tipo Artifact
   «Design» (`Artifact` action `quickstart` intent `design`, poi publish con il suo `type_url`): Home giorno e notte,
   slitta (e il pomello di riserva), pop-up regalo, icona sulla schermata Home di iOS. Mandami il link: lo giro io a
   William. Se William commenta sulla tela, rispondi solo correggendo la tela e avvisa me di ogni commento.
5. PR verso `main` (non bozza), non unirla.

## Riuscita
William apre la tela e dice che gli piace. Il Developer ha asset pronti e misure senza domande. Crediti spesi entro il
tetto, tutti annotati.

## Non fare
Non toccare il codice Swift. Non superare i 39 crediti né comprare nulla. Non unire. Non scrivere a William fuori dalla
tela. Niente riferimenti religiosi.

## Esito
